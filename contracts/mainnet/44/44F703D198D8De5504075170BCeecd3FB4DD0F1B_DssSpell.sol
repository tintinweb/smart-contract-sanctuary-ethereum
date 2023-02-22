/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: MIT AND AGPL-3.0-or-later
pragma solidity =0.8.16 >=0.5.12 >=0.8.0 >=0.6.0 <0.9.0 >=0.6.2 <0.9.0 >=0.8.16 <0.9.0;
pragma experimental ABIEncoderV2;

////// lib/dss-exec-lib/lib/forge-std/src/Vm.sol
/* pragma solidity >=0.6.2 <0.9.0; */

/* pragma experimental ABIEncoderV2; */

// Cheatcodes are marked as view/pure/none using the following rules:
// 0. A call's observable behaviour includes its return value, logs, reverts and state writes,
// 1. If you can influence a later call's observable behaviour, you're neither `view` nor `pure (you are modifying some state be it the EVM, interpreter, filesystem, etc),
// 2. Otherwise if you can be influenced by an earlier call, or if reading some state, you're `view`,
// 3. Otherwise you're `pure`.

interface VmSafe {
    struct Log {
        bytes32[] topics;
        bytes data;
        address emitter;
    }

    struct Rpc {
        string key;
        string url;
    }

    struct FsMetadata {
        bool isDir;
        bool isSymlink;
        uint256 length;
        bool readOnly;
        uint256 modified;
        uint256 accessed;
        uint256 created;
    }

    // Loads a storage slot from an address
    function load(address target, bytes32 slot) external view returns (bytes32 data);
    // Signs data
    function sign(uint256 privateKey, bytes32 digest) external pure returns (uint8 v, bytes32 r, bytes32 s);
    // Gets the address for a given private key
    function addr(uint256 privateKey) external pure returns (address keyAddr);
    // Gets the nonce of an account
    function getNonce(address account) external view returns (uint64 nonce);
    // Performs a foreign function call via the terminal
    function ffi(string[] calldata commandInput) external returns (bytes memory result);
    // Sets environment variables
    function setEnv(string calldata name, string calldata value) external;
    // Reads environment variables, (name) => (value)
    function envBool(string calldata name) external view returns (bool value);
    function envUint(string calldata name) external view returns (uint256 value);
    function envInt(string calldata name) external view returns (int256 value);
    function envAddress(string calldata name) external view returns (address value);
    function envBytes32(string calldata name) external view returns (bytes32 value);
    function envString(string calldata name) external view returns (string memory value);
    function envBytes(string calldata name) external view returns (bytes memory value);
    // Reads environment variables as arrays
    function envBool(string calldata name, string calldata delim) external view returns (bool[] memory value);
    function envUint(string calldata name, string calldata delim) external view returns (uint256[] memory value);
    function envInt(string calldata name, string calldata delim) external view returns (int256[] memory value);
    function envAddress(string calldata name, string calldata delim) external view returns (address[] memory value);
    function envBytes32(string calldata name, string calldata delim) external view returns (bytes32[] memory value);
    function envString(string calldata name, string calldata delim) external view returns (string[] memory value);
    function envBytes(string calldata name, string calldata delim) external view returns (bytes[] memory value);
    // Read environment variables with default value
    function envOr(string calldata name, bool defaultValue) external returns (bool value);
    function envOr(string calldata name, uint256 defaultValue) external returns (uint256 value);
    function envOr(string calldata name, int256 defaultValue) external returns (int256 value);
    function envOr(string calldata name, address defaultValue) external returns (address value);
    function envOr(string calldata name, bytes32 defaultValue) external returns (bytes32 value);
    function envOr(string calldata name, string calldata defaultValue) external returns (string memory value);
    function envOr(string calldata name, bytes calldata defaultValue) external returns (bytes memory value);
    // Read environment variables as arrays with default value
    function envOr(string calldata name, string calldata delim, bool[] calldata defaultValue)
        external
        returns (bool[] memory value);
    function envOr(string calldata name, string calldata delim, uint256[] calldata defaultValue)
        external
        returns (uint256[] memory value);
    function envOr(string calldata name, string calldata delim, int256[] calldata defaultValue)
        external
        returns (int256[] memory value);
    function envOr(string calldata name, string calldata delim, address[] calldata defaultValue)
        external
        returns (address[] memory value);
    function envOr(string calldata name, string calldata delim, bytes32[] calldata defaultValue)
        external
        returns (bytes32[] memory value);
    function envOr(string calldata name, string calldata delim, string[] calldata defaultValue)
        external
        returns (string[] memory value);
    function envOr(string calldata name, string calldata delim, bytes[] calldata defaultValue)
        external
        returns (bytes[] memory value);
    // Records all storage reads and writes
    function record() external;
    // Gets all accessed reads and write slot from a recording session, for a given address
    function accesses(address target) external returns (bytes32[] memory readSlots, bytes32[] memory writeSlots);
    // Gets the _creation_ bytecode from an artifact file. Takes in the relative path to the json file
    function getCode(string calldata artifactPath) external view returns (bytes memory creationBytecode);
    // Gets the _deployed_ bytecode from an artifact file. Takes in the relative path to the json file
    function getDeployedCode(string calldata artifactPath) external view returns (bytes memory runtimeBytecode);
    // Labels an address in call traces
    function label(address account, string calldata newLabel) external;
    // Using the address that calls the test contract, has the next call (at this call depth only) create a transaction that can later be signed and sent onchain
    function broadcast() external;
    // Has the next call (at this call depth only) create a transaction with the address provided as the sender that can later be signed and sent onchain
    function broadcast(address signer) external;
    // Has the next call (at this call depth only) create a transaction with the private key provided as the sender that can later be signed and sent onchain
    function broadcast(uint256 privateKey) external;
    // Using the address that calls the test contract, has all subsequent calls (at this call depth only) create transactions that can later be signed and sent onchain
    function startBroadcast() external;
    // Has all subsequent calls (at this call depth only) create transactions with the address provided that can later be signed and sent onchain
    function startBroadcast(address signer) external;
    // Has all subsequent calls (at this call depth only) create transactions with the private key provided that can later be signed and sent onchain
    function startBroadcast(uint256 privateKey) external;
    // Stops collecting onchain transactions
    function stopBroadcast() external;
    // Reads the entire content of file to string
    function readFile(string calldata path) external view returns (string memory data);
    // Reads the entire content of file as binary. Path is relative to the project root.
    function readFileBinary(string calldata path) external view returns (bytes memory data);
    // Get the path of the current project root
    function projectRoot() external view returns (string memory path);
    // Get the metadata for a file/directory
    function fsMetadata(string calldata fileOrDir) external returns (FsMetadata memory metadata);
    // Reads next line of file to string
    function readLine(string calldata path) external view returns (string memory line);
    // Writes data to file, creating a file if it does not exist, and entirely replacing its contents if it does.
    function writeFile(string calldata path, string calldata data) external;
    // Writes binary data to a file, creating a file if it does not exist, and entirely replacing its contents if it does.
    // Path is relative to the project root.
    function writeFileBinary(string calldata path, bytes calldata data) external;
    // Writes line to file, creating a file if it does not exist.
    function writeLine(string calldata path, string calldata data) external;
    // Closes file for reading, resetting the offset and allowing to read it from beginning with readLine.
    function closeFile(string calldata path) external;
    // Removes file. This cheatcode will revert in the following situations, but is not limited to just these cases:
    // - Path points to a directory.
    // - The file doesn't exist.
    // - The user lacks permissions to remove the file.
    function removeFile(string calldata path) external;
    // Convert values to a string
    function toString(address value) external pure returns (string memory stringifiedValue);
    function toString(bytes calldata value) external pure returns (string memory stringifiedValue);
    function toString(bytes32 value) external pure returns (string memory stringifiedValue);
    function toString(bool value) external pure returns (string memory stringifiedValue);
    function toString(uint256 value) external pure returns (string memory stringifiedValue);
    function toString(int256 value) external pure returns (string memory stringifiedValue);
    // Convert values from a string
    function parseBytes(string calldata stringifiedValue) external pure returns (bytes memory parsedValue);
    function parseAddress(string calldata stringifiedValue) external pure returns (address parsedValue);
    function parseUint(string calldata stringifiedValue) external pure returns (uint256 parsedValue);
    function parseInt(string calldata stringifiedValue) external pure returns (int256 parsedValue);
    function parseBytes32(string calldata stringifiedValue) external pure returns (bytes32 parsedValue);
    function parseBool(string calldata stringifiedValue) external pure returns (bool parsedValue);
    // Record all the transaction logs
    function recordLogs() external;
    // Gets all the recorded logs
    function getRecordedLogs() external returns (Log[] memory logs);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at the derivation path m/44'/60'/0'/0/{index}
    function deriveKey(string calldata mnemonic, uint32 index) external pure returns (uint256 privateKey);
    // Derive a private key from a provided mnenomic string (or mnenomic file path) at {derivationPath}{index}
    function deriveKey(string calldata mnemonic, string calldata derivationPath, uint32 index)
        external
        pure
        returns (uint256 privateKey);
    // Adds a private key to the local forge wallet and returns the address
    function rememberKey(uint256 privateKey) external returns (address keyAddr);
    //
    // parseJson
    //
    // ----
    // In case the returned value is a JSON object, it's encoded as a ABI-encoded tuple. As JSON objects
    // don't have the notion of ordered, but tuples do, they JSON object is encoded with it's fields ordered in
    // ALPHABETICAL order. That means that in order to successfully decode the tuple, we need to define a tuple that
    // encodes the fields in the same order, which is alphabetical. In the case of Solidity structs, they are encoded
    // as tuples, with the attributes in the order in which they are defined.
    // For example: json = { 'a': 1, 'b': 0xa4tb......3xs}
    // a: uint256
    // b: address
    // To decode that json, we need to define a struct or a tuple as follows:
    // struct json = { uint256 a; address b; }
    // If we defined a json struct with the opposite order, meaning placing the address b first, it would try to
    // decode the tuple in that order, and thus fail.
    // ----
    // Given a string of JSON, return it as ABI-encoded
    function parseJson(string calldata json, string calldata key) external pure returns (bytes memory abiEncodedData);
    function parseJson(string calldata json) external pure returns (bytes memory abiEncodedData);

    // The following parseJson cheatcodes will do type coercion, for the type that they indicate.
    // For example, parseJsonUint will coerce all values to a uint256. That includes stringified numbers '12'
    // and hex numbers '0xEF'.
    // Type coercion works ONLY for discrete values or arrays. That means that the key must return a value or array, not
    // a JSON object.
    function parseJsonUint(string calldata, string calldata) external returns (uint256);
    function parseJsonUintArray(string calldata, string calldata) external returns (uint256[] memory);
    function parseJsonInt(string calldata, string calldata) external returns (int256);
    function parseJsonIntArray(string calldata, string calldata) external returns (int256[] memory);
    function parseJsonBool(string calldata, string calldata) external returns (bool);
    function parseJsonBoolArray(string calldata, string calldata) external returns (bool[] memory);
    function parseJsonAddress(string calldata, string calldata) external returns (address);
    function parseJsonAddressArray(string calldata, string calldata) external returns (address[] memory);
    function parseJsonString(string calldata, string calldata) external returns (string memory);
    function parseJsonStringArray(string calldata, string calldata) external returns (string[] memory);
    function parseJsonBytes(string calldata, string calldata) external returns (bytes memory);
    function parseJsonBytesArray(string calldata, string calldata) external returns (bytes[] memory);
    function parseJsonBytes32(string calldata, string calldata) external returns (bytes32);
    function parseJsonBytes32Array(string calldata, string calldata) external returns (bytes32[] memory);

    // Serialize a key and value to a JSON object stored in-memory that can be later written to a file
    // It returns the stringified version of the specific JSON file up to that moment.
    function serializeBool(string calldata objectKey, string calldata valueKey, bool value)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256 value)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256 value)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address value)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32 value)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string calldata value)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes calldata value)
        external
        returns (string memory json);

    function serializeBool(string calldata objectKey, string calldata valueKey, bool[] calldata values)
        external
        returns (string memory json);
    function serializeUint(string calldata objectKey, string calldata valueKey, uint256[] calldata values)
        external
        returns (string memory json);
    function serializeInt(string calldata objectKey, string calldata valueKey, int256[] calldata values)
        external
        returns (string memory json);
    function serializeAddress(string calldata objectKey, string calldata valueKey, address[] calldata values)
        external
        returns (string memory json);
    function serializeBytes32(string calldata objectKey, string calldata valueKey, bytes32[] calldata values)
        external
        returns (string memory json);
    function serializeString(string calldata objectKey, string calldata valueKey, string[] calldata values)
        external
        returns (string memory json);
    function serializeBytes(string calldata objectKey, string calldata valueKey, bytes[] calldata values)
        external
        returns (string memory json);

    //
    // writeJson
    //
    // ----
    // Write a serialized JSON object to a file. If the file exists, it will be overwritten.
    // Let's assume we want to write the following JSON to a file:
    //
    // { "boolean": true, "number": 342, "object": { "title": "finally json serialization" } }
    //
    // ```
    //  string memory json1 = "some key";
    //  vm.serializeBool(json1, "boolean", true);
    //  vm.serializeBool(json1, "number", uint256(342));
    //  json2 = "some other key";
    //  string memory output = vm.serializeString(json2, "title", "finally json serialization");
    //  string memory finalJson = vm.serialize(json1, "object", output);
    //  vm.writeJson(finalJson, "./output/example.json");
    // ```
    // The critical insight is that every invocation of serialization will return the stringified version of the JSON
    // up to that point. That means we can construct arbitrary JSON objects and then use the return stringified version
    // to serialize them as values to another JSON object.
    //
    // json1 and json2 are simply keys used by the backend to keep track of the objects. So vm.serializeJson(json1,..)
    // will find the object in-memory that is keyed by "some key".
    function writeJson(string calldata json, string calldata path) external;
    // Write a serialized JSON object to an **existing** JSON file, replacing a value with key = <value_key>
    // This is useful to replace a specific value of a JSON file, without having to parse the entire thing
    function writeJson(string calldata json, string calldata path, string calldata valueKey) external;
    // Returns the RPC url for the given alias
    function rpcUrl(string calldata rpcAlias) external view returns (string memory json);
    // Returns all rpc urls and their aliases `[alias, url][]`
    function rpcUrls() external view returns (string[2][] memory urls);
    // Returns all rpc urls and their aliases as structs.
    function rpcUrlStructs() external view returns (Rpc[] memory urls);
    // If the condition is false, discard this run's fuzz inputs and generate new ones.
    function assume(bool condition) external pure;
    // Pauses gas metering (i.e. gas usage is not counted). Noop if already paused.
    function pauseGasMetering() external;
    // Resumes gas metering (i.e. gas usage is counted again). Noop if already on.
    function resumeGasMetering() external;
}

interface Vm is VmSafe {
    // Sets block.timestamp
    function warp(uint256 newTimestamp) external;
    // Sets block.height
    function roll(uint256 newHeight) external;
    // Sets block.basefee
    function fee(uint256 newBasefee) external;
    // Sets block.difficulty
    function difficulty(uint256 newDifficulty) external;
    // Sets block.chainid
    function chainId(uint256 newChainId) external;
    // Stores a value to an address' storage slot.
    function store(address target, bytes32 slot, bytes32 value) external;
    // Sets the nonce of an account; must be higher than the current nonce of the account
    function setNonce(address account, uint64 newNonce) external;
    // Sets the *next* call's msg.sender to be the input address
    function prank(address msgSender) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called
    function startPrank(address msgSender) external;
    // Sets the *next* call's msg.sender to be the input address, and the tx.origin to be the second input
    function prank(address msgSender, address txOrigin) external;
    // Sets all subsequent calls' msg.sender to be the input address until `stopPrank` is called, and the tx.origin to be the second input
    function startPrank(address msgSender, address txOrigin) external;
    // Resets subsequent calls' msg.sender to be `address(this)`
    function stopPrank() external;
    // Sets an address' balance
    function deal(address account, uint256 newBalance) external;
    // Sets an address' code
    function etch(address target, bytes calldata newRuntimeBytecode) external;
    // Expects an error on next call
    function expectRevert(bytes calldata revertData) external;
    function expectRevert(bytes4 revertData) external;
    function expectRevert() external;
    // Prepare an expected log with (bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData).
    // Call this function, then emit an event, then call a function. Internally after the call, we check if
    // logs were emitted in the expected order with the expected topics and data (as specified by the booleans)
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData) external;
    function expectEmit(bool checkTopic1, bool checkTopic2, bool checkTopic3, bool checkData, address emitter)
        external;
    // Mocks a call to an address, returning specified data.
    // Calldata can either be strict or a partial match, e.g. if you only
    // pass a Solidity selector to the expected calldata, then the entire Solidity
    // function will be mocked.
    function mockCall(address callee, bytes calldata data, bytes calldata returnData) external;
    // Mocks a call to an address with a specific msg.value, returning specified data.
    // Calldata match takes precedence over msg.value in case of ambiguity.
    function mockCall(address callee, uint256 msgValue, bytes calldata data, bytes calldata returnData) external;
    // Clears all mocked calls
    function clearMockedCalls() external;
    // Expects a call to an address with the specified calldata.
    // Calldata can either be a strict or a partial match
    function expectCall(address callee, bytes calldata data) external;
    // Expects a call to an address with the specified msg.value and calldata
    function expectCall(address callee, uint256 msgValue, bytes calldata data) external;
    // Sets block.coinbase
    function coinbase(address newCoinbase) external;
    // Snapshot the current state of the evm.
    // Returns the id of the snapshot that was created.
    // To revert a snapshot use `revertTo`
    function snapshot() external returns (uint256 snapshotId);
    // Revert the state of the EVM to a previous snapshot
    // Takes the snapshot id to revert to.
    // This deletes the snapshot and all snapshots taken after the given snapshot id.
    function revertTo(uint256 snapshotId) external returns (bool success);
    // Creates a new fork with the given endpoint and block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);
    // Creates a new fork with the given endpoint and the _latest_ block and returns the identifier of the fork
    function createFork(string calldata urlOrAlias) external returns (uint256 forkId);
    // Creates a new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before the transaction,
    // and returns the identifier of the fork
    function createFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);
    // Creates _and_ also selects a new fork with the given endpoint and block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, uint256 blockNumber) external returns (uint256 forkId);
    // Creates _and_ also selects new fork with the given endpoint and at the block the given transaction was mined in, replays all transaction mined in the block before
    // the transaction, returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias, bytes32 txHash) external returns (uint256 forkId);
    // Creates _and_ also selects a new fork with the given endpoint and the latest block and returns the identifier of the fork
    function createSelectFork(string calldata urlOrAlias) external returns (uint256 forkId);
    // Takes a fork identifier created by `createFork` and sets the corresponding forked state as active.
    function selectFork(uint256 forkId) external;
    /// Returns the identifier of the currently active fork. Reverts if no fork is currently active.
    function activeFork() external view returns (uint256 forkId);
    // Updates the currently active fork to given block number
    // This is similar to `roll` but for the currently active fork
    function rollFork(uint256 blockNumber) external;
    // Updates the currently active fork to given transaction
    // this will `rollFork` with the number of the block the transaction was mined in and replays all transaction mined before it in the block
    function rollFork(bytes32 txHash) external;
    // Updates the given fork to given block number
    function rollFork(uint256 forkId, uint256 blockNumber) external;
    // Updates the given fork to block number of the given transaction and replays all transaction mined before it in the block
    function rollFork(uint256 forkId, bytes32 txHash) external;
    // Marks that the account(s) should use persistent storage across fork swaps in a multifork setup
    // Meaning, changes made to the state of this account will be kept when switching forks
    function makePersistent(address account) external;
    function makePersistent(address account0, address account1) external;
    function makePersistent(address account0, address account1, address account2) external;
    function makePersistent(address[] calldata accounts) external;
    // Revokes persistent status from the address, previously added via `makePersistent`
    function revokePersistent(address account) external;
    function revokePersistent(address[] calldata accounts) external;
    // Returns true if the account is marked as persistent
    function isPersistent(address account) external view returns (bool persistent);
    // In forking mode, explicitly grant the given address cheatcode access
    function allowCheatcodes(address account) external;
    // Fetches the given transaction from the active fork and executes it on the current state
    function transact(bytes32 txHash) external;
    // Fetches the given transaction from the given fork and executes it on the current state
    function transact(uint256 forkId, bytes32 txHash) external;
}

////// lib/dss-exec-lib/lib/forge-std/src/StdJson.sol
/* pragma solidity >=0.6.0 <0.9.0; */

/* pragma experimental ABIEncoderV2; */

/* import {VmSafe} from "./Vm.sol"; */

// Helpers for parsing and writing JSON files
// To parse:
// ```
// using stdJson for string;
// string memory json = vm.readFile("some_peth");
// json.parseUint("<json_path>");
// ```
// To write:
// ```
// using stdJson for string;
// string memory json = "deploymentArtifact";
// Contract contract = new Contract();
// json.serialize("contractAddress", address(contract));
// json = json.serialize("deploymentTimes", uint(1));
// // store the stringified JSON to the 'json' variable we have been using as a key
// // as we won't need it any longer
// string memory json2 = "finalArtifact";
// string memory final = json2.serialize("depArtifact", json);
// final.write("<some_path>");
// ```

library stdJson {
    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function parseRaw(string memory json, string memory key) internal pure returns (bytes memory) {
        return vm.parseJson(json, key);
    }

    function readUint(string memory json, string memory key) internal pure returns (uint256) {
        return abi.decode(vm.parseJson(json, key), (uint256));
    }

    function readUintArray(string memory json, string memory key) internal pure returns (uint256[] memory) {
        return abi.decode(vm.parseJson(json, key), (uint256[]));
    }

    function readInt(string memory json, string memory key) internal pure returns (int256) {
        return abi.decode(vm.parseJson(json, key), (int256));
    }

    function readIntArray(string memory json, string memory key) internal pure returns (int256[] memory) {
        return abi.decode(vm.parseJson(json, key), (int256[]));
    }

    function readBytes32(string memory json, string memory key) internal pure returns (bytes32) {
        return abi.decode(vm.parseJson(json, key), (bytes32));
    }

    function readBytes32Array(string memory json, string memory key) internal pure returns (bytes32[] memory) {
        return abi.decode(vm.parseJson(json, key), (bytes32[]));
    }

    function readString(string memory json, string memory key) internal pure returns (string memory) {
        return abi.decode(vm.parseJson(json, key), (string));
    }

    function readStringArray(string memory json, string memory key) internal pure returns (string[] memory) {
        return abi.decode(vm.parseJson(json, key), (string[]));
    }

    function readAddress(string memory json, string memory key) internal pure returns (address) {
        return abi.decode(vm.parseJson(json, key), (address));
    }

    function readAddressArray(string memory json, string memory key) internal pure returns (address[] memory) {
        return abi.decode(vm.parseJson(json, key), (address[]));
    }

    function readBool(string memory json, string memory key) internal pure returns (bool) {
        return abi.decode(vm.parseJson(json, key), (bool));
    }

    function readBoolArray(string memory json, string memory key) internal pure returns (bool[] memory) {
        return abi.decode(vm.parseJson(json, key), (bool[]));
    }

    function readBytes(string memory json, string memory key) internal pure returns (bytes memory) {
        return abi.decode(vm.parseJson(json, key), (bytes));
    }

    function readBytesArray(string memory json, string memory key) internal pure returns (bytes[] memory) {
        return abi.decode(vm.parseJson(json, key), (bytes[]));
    }

    function serialize(string memory jsonKey, string memory key, bool value) internal returns (string memory) {
        return vm.serializeBool(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bool[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBool(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, uint256 value) internal returns (string memory) {
        return vm.serializeUint(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, uint256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeUint(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, int256 value) internal returns (string memory) {
        return vm.serializeInt(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, int256[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeInt(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, address value) internal returns (string memory) {
        return vm.serializeAddress(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, address[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeAddress(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes32 value) internal returns (string memory) {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes32[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes32(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes memory value) internal returns (string memory) {
        return vm.serializeBytes(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, bytes[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeBytes(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, string memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    function serialize(string memory jsonKey, string memory key, string[] memory value)
        internal
        returns (string memory)
    {
        return vm.serializeString(jsonKey, key, value);
    }

    function write(string memory jsonKey, string memory path) internal {
        vm.writeJson(jsonKey, path);
    }

    function write(string memory jsonKey, string memory path, string memory valueKey) internal {
        vm.writeJson(jsonKey, path, valueKey);
    }
}

////// lib/dss-exec-lib/src/CollateralOpts.sol
//
// CollateralOpts.sol -- Data structure for onboarding collateral
//
// Copyright (C) 2020-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity ^0.8.16; */

struct CollateralOpts {
    bytes32 ilk;
    address gem;
    address join;
    address clip;
    address calc;
    address pip;
    bool    isLiquidatable;
    bool    isOSM;
    bool    whitelistOSM;
    uint256 ilkDebtCeiling;
    uint256 minVaultAmount;
    uint256 maxLiquidationAmount;
    uint256 liquidationPenalty;
    uint256 ilkStabilityFee;
    uint256 startingPriceFactor;
    uint256 breakerTolerance;
    uint256 auctionDuration;
    uint256 permittedDrop;
    uint256 liquidationRatio;
    uint256 kprFlatReward;
    uint256 kprPctReward;
}

////// lib/dss-exec-lib/src/DssExecLib.sol
//
// DssExecLib.sol -- MakerDAO Executive Spellcrafting Library
//
// Copyright (C) 2020-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity ^0.8.16; */

/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface Initializable {
    function init(bytes32) external;
}

interface Authorizable {
    function rely(address) external;
    function deny(address) external;
    function setAuthority(address) external;
}

interface Fileable {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
}

interface Drippable {
    function drip() external returns (uint256);
    function drip(bytes32) external returns (uint256);
}

interface Pricing {
    function poke(bytes32) external;
}

interface ERC20 {
    function decimals() external returns (uint8);
}

interface DssVat {
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
    function Line() external view returns (uint256);
    function suck(address, address, uint256) external;
}

interface ClipLike {
    function vat() external returns (address);
    function dog() external returns (address);
    function spotter() external view returns (address);
    function calc() external view returns (address);
    function ilk() external returns (bytes32);
}

interface DogLike {
    function ilks(bytes32) external returns (address clip, uint256 chop, uint256 hole, uint256 dirt);
}

interface JoinLike {
    function vat() external returns (address);
    function ilk() external returns (bytes32);
    function gem() external returns (address);
    function dec() external returns (uint256);
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// Includes Median and OSM functions
interface OracleLike_2 {
    function src() external view returns (address);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface MomLike {
    function setOsm(bytes32, address) external;
    function setPriceTolerance(address, uint256) external;
}

interface RegistryLike {
    function add(address) external;
    function xlip(bytes32) external view returns (address);
}

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike {
    function setVersion(string calldata) external;
    function setIPFS(string calldata) external;
    function setSha256sum(string calldata) external;
    function getAddress(bytes32) external view returns (address);
    function setAddress(bytes32, address) external;
    function removeAddress(bytes32) external;
}

interface IAMLike {
    function ilks(bytes32) external view returns (uint256,uint256,uint48,uint48,uint48);
    function setIlk(bytes32,uint256,uint256,uint256) external;
    function remIlk(bytes32) external;
    function exec(bytes32) external returns (uint256);
}

interface LerpFactoryLike {
    function newLerp(bytes32 name_, address target_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
    function newIlkLerp(bytes32 name_, address target_, bytes32 ilk_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
}

interface LerpLike {
    function tick() external returns (uint256);
}

interface RwaOracleLike {
    function bump(bytes32 ilk, uint256 val) external;
}


library DssExecLib {

    /*****************/
    /*** Constants ***/
    /*****************/
    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    uint256 constant internal WAD      = 10 ** 18;
    uint256 constant internal RAY      = 10 ** 27;
    uint256 constant internal RAD      = 10 ** 45;
    uint256 constant internal THOUSAND = 10 ** 3;
    uint256 constant internal MILLION  = 10 ** 6;

    uint256 constant internal BPS_ONE_PCT             = 100;
    uint256 constant internal BPS_ONE_HUNDRED_PCT     = 100 * BPS_ONE_PCT;
    uint256 constant internal RATES_ONE_HUNDRED_PCT   = 1000000021979553151239153027;

    /**********************/
    /*** Math Functions ***/
    /**********************/
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * WAD + y / 2) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = (x * RAY + y / 2) / y;
    }

    /****************************/
    /*** Core Address Helpers ***/
    /****************************/
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        public view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function dog()        public view returns (address) { return getChangelogAddress("MCD_DOG"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function esm()        public view returns (address) { return getChangelogAddress("MCD_ESM"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function flap()       public view returns (address) { return getChangelogAddress("MCD_FLAP"); }
    function flop()       public view returns (address) { return getChangelogAddress("MCD_FLOP"); }
    function osmMom()     public view returns (address) { return getChangelogAddress("OSM_MOM"); }
    function govGuard()   public view returns (address) { return getChangelogAddress("GOV_GUARD"); }
    function flipperMom() public view returns (address) { return getChangelogAddress("FLIPPER_MOM"); }
    function clipperMom() public view returns (address) { return getChangelogAddress("CLIPPER_MOM"); }
    function pauseProxy() public view returns (address) { return getChangelogAddress("MCD_PAUSE_PROXY"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }

    function clip(bytes32 _ilk) public view returns (address _clip) {
        _clip = RegistryLike(reg()).xlip(_ilk);
    }

    function flip(bytes32 _ilk) public view returns (address _flip) {
        _flip = RegistryLike(reg()).xlip(_ilk);
    }

    function calc(bytes32 _ilk) public view returns (address _calc) {
        _calc = ClipLike(clip(_ilk)).calc();
    }

    function getChangelogAddress(bytes32 _key) public view returns (address) {
        return ChainlogLike(LOG).getAddress(_key);
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/
    /**
        @dev Set an address in the MCD on-chain changelog.
        @param _key Access key for the address (e.g. "MCD_VAT")
        @param _val The address associated with the _key
    */
    function setChangelogAddress(bytes32 _key, address _val) public {
        ChainlogLike(LOG).setAddress(_key, _val);
    }

    /**
        @dev Set version in the MCD on-chain changelog.
        @param _version Changelog version (e.g. "1.1.2")
    */
    function setChangelogVersion(string memory _version) public {
        ChainlogLike(LOG).setVersion(_version);
    }
    /**
        @dev Set IPFS hash of IPFS changelog in MCD on-chain changelog.
        @param _ipfsHash IPFS hash (e.g. "QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW")
    */
    function setChangelogIPFS(string memory _ipfsHash) public {
        ChainlogLike(LOG).setIPFS(_ipfsHash);
    }
    /**
        @dev Set SHA256 hash in MCD on-chain changelog.
        @param _SHA256Sum SHA256 hash (e.g. "e42dc9d043a57705f3f097099e6b2de4230bca9a020c797508da079f9079e35b")
    */
    function setChangelogSHA256(string memory _SHA256Sum) public {
        ChainlogLike(LOG).setSha256sum(_SHA256Sum);
    }


    /**********************/
    /*** Authorizations ***/
    /**********************/
    /**
        @dev Give an address authorization to perform auth actions on the contract.
        @param _base   The address of the contract where the authorization will be set
        @param _ward   Address to be authorized
    */
    function authorize(address _base, address _ward) public {
        Authorizable(_base).rely(_ward);
    }
    /**
        @dev Revoke contract authorization from an address.
        @param _base   The address of the contract where the authorization will be revoked
        @param _ward   Address to be deauthorized
    */
    function deauthorize(address _base, address _ward) public {
        Authorizable(_base).deny(_ward);
    }
    /**
        @dev Give an address authorization to perform auth actions on the contract.
        @param _base   The address of the contract with a `setAuthority` pattern
        @param _authority   Address to be authorized
    */
    function setAuthority(address _base, address _authority) public {
        Authorizable(_base).setAuthority(_authority);
    }
    /**
        @dev Delegate vat authority to the specified address.
        @param _usr Address to be authorized
    */
    function delegateVat(address _usr) public {
        DssVat(vat()).hope(_usr);
    }
    /**
        @dev Revoke vat authority to the specified address.
        @param _usr Address to be deauthorized
    */
    function undelegateVat(address _usr) public {
        DssVat(vat()).nope(_usr);
    }

    /******************************/
    /*** OfficeHours Management ***/
    /******************************/

    /**
        @dev Returns true if a time is within office hours range
        @param _ts           The timestamp to check, usually block.timestamp
        @param _officeHours  true if office hours is enabled.
        @return              true if time is in castable range
    */
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {
        if (_officeHours) {
            uint256 day = (_ts / 1 days + 3) % 7;
            if (day >= 5)                 { return false; }  // Can only be cast on a weekday
            uint256 hour = _ts / 1 hours % 24;
            if (hour < 14 || hour >= 21)  { return false; }  // Outside office hours
        }
        return true;
    }

    /**
        @dev Calculate the next available cast time in epoch seconds
        @param _eta          The scheduled time of the spell plus the pause delay
        @param _ts           The current timestamp, usually block.timestamp
        @param _officeHours  true if office hours is enabled.
        @return castTime     The next available cast timestamp
    */
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {
        require(_eta != 0);  // "DssExecLib/invalid eta"
        require(_ts  != 0);  // "DssExecLib/invalid ts"
        castTime = _ts > _eta ? _ts : _eta; // Any day at XX:YY

        if (_officeHours) {
            uint256 day    = (castTime / 1 days + 3) % 7;
            uint256 hour   = castTime / 1 hours % 24;
            uint256 minute = castTime / 1 minutes % 60;
            uint256 second = castTime % 60;

            if (day >= 5) {
                castTime += (6 - day) * 1 days;                 // Go to Sunday XX:YY
                castTime += (24 - hour + 14) * 1 hours;         // Go to 14:YY UTC Monday
                castTime -= minute * 1 minutes + second;        // Go to 14:00 UTC
            } else {
                if (hour >= 21) {
                    if (day == 4) castTime += 2 days;           // If Friday, fast forward to Sunday XX:YY
                    castTime += (24 - hour + 14) * 1 hours;     // Go to 14:YY UTC next day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                } else if (hour < 14) {
                    castTime += (14 - hour) * 1 hours;          // Go to 14:YY UTC same day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                }
            }
        }
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    /**
        @dev Update rate accumulation for the Dai Savings Rate (DSR).
    */
    function accumulateDSR() public {
        Drippable(pot()).drip();
    }
    /**
        @dev Update rate accumulation for the stability fees of a given collateral type.
        @param _ilk   Collateral type
    */
    function accumulateCollateralStabilityFees(bytes32 _ilk) public {
        Drippable(jug()).drip(_ilk);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    /**
        @dev Update price of a given collateral type.
        @param _ilk   Collateral type
    */
    function updateCollateralPrice(bytes32 _ilk) public {
        Pricing(spotter()).poke(_ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    /**
        @dev Set a contract in another contract, defining the relationship (ex. set a new Calc contract in Clip)
        @param _base   The address of the contract where the new contract address will be filed
        @param _what   Name of contract to file
        @param _addr   Address of contract to file
    */
    function setContract(address _base, bytes32 _what, address _addr) public {
        Fileable(_base).file(_what, _addr);
    }
    /**
        @dev Set a contract in another contract, defining the relationship (ex. set a new Calc contract in a Clip)
        @param _base   The address of the contract where the new contract address will be filed
        @param _ilk    Collateral type
        @param _what   Name of contract to file
        @param _addr   Address of contract to file
    */
    function setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr) public {
        Fileable(_base).file(_ilk, _what, _addr);
    }
    /**
        @dev Set a value in a contract, via a governance authorized File pattern.
        @param _base   The address of the contract where the new contract address will be filed
        @param _what   Name of tag for the value (e.x. "Line")
        @param _amt    The value to set or update
    */
    function setValue(address _base, bytes32 _what, uint256 _amt) public {
        Fileable(_base).file(_what, _amt);
    }
    /**
        @dev Set an ilk-specific value in a contract, via a governance authorized File pattern.
        @param _base   The address of the contract where the new value will be filed
        @param _ilk    Collateral type
        @param _what   Name of tag for the value (e.x. "Line")
        @param _amt    The value to set or update
    */
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {
        Fileable(_base).file(_ilk, _what, _amt);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    // function setGlobalDebtCeiling(uint256 _amount) public { setGlobalDebtCeiling(vat(), _amount); }
    /**
        @dev Set the global debt ceiling. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-global-Line-precision"
        setValue(vat(), "Line", _amount * RAD);
    }
    /**
        @dev Increase the global debt ceiling by a specific amount. Amount will be converted to the correct internal precision.
        @param _amount The amount to add in DAI (ex. 10m DAI amount == 10000000)
    */
    function increaseGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-Line-increase-precision"
        address _vat = vat();
        setValue(_vat, "Line", DssVat(_vat).Line() + _amount * RAD);
    }
    /**
        @dev Decrease the global debt ceiling by a specific amount. Amount will be converted to the correct internal precision.
        @param _amount The amount to reduce in DAI (ex. 10m DAI amount == 10000000)
    */
    function decreaseGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-Line-decrease-precision"
        address _vat = vat();
        setValue(_vat, "Line", DssVat(_vat).Line() - _amount * RAD);
    }
    /**
        @dev Set the Dai Savings Rate. See: docs/rates.txt
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
        @param _doDrip `true` to accumulate interest owed
    */
    function setDSR(uint256 _rate, bool _doDrip) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT));  // "LibDssExec/dsr-out-of-bounds"
        if (_doDrip) Drippable(pot()).drip();
        setValue(pot(), "dsr", _rate);
    }
    /**
        @dev Set the DAI amount for system surplus auctions. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusAuctionAmount(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-bump-precision"
        setValue(vow(), "bump", _amount * RAD);
    }
    /**
        @dev Set the DAI amount for system surplus buffer, must be exceeded before surplus auctions start. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusBuffer(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-hump-precision"
        setValue(vow(), "hump", _amount * RAD);
    }
    /**
        @dev Set minimum bid increase for surplus auctions. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setMinSurplusAuctionBidIncrease(uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-flap-beg-precision"
        setValue(flap(), "beg", WAD + wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }
    /**
        @dev Set bid duration for surplus auctions.
        @param _duration Amount of time for bids. (in seconds)
    */
    function setSurplusAuctionBidDuration(uint256 _duration) public {
        setValue(flap(), "ttl", _duration);
    }
    /**
        @dev Set total auction duration for surplus auctions.
        @param _duration Amount of time for auctions. (in seconds)
    */
    function setSurplusAuctionDuration(uint256 _duration) public {
        setValue(flap(), "tau", _duration);
    }
    /**
        @dev Set the number of seconds that pass before system debt is auctioned for MKR tokens.
        @param _duration Duration in seconds
    */
    function setDebtAuctionDelay(uint256 _duration) public {
        setValue(vow(), "wait", _duration);
    }
    /**
        @dev Set the DAI amount for system debt to be covered by each debt auction. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setDebtAuctionDAIAmount(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-sump-precision"
        setValue(vow(), "sump", _amount * RAD);
    }
    /**
        @dev Set the starting MKR amount to be auctioned off to cover system debt in debt auctions. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in MKR (ex. 250 MKR amount == 250)
    */
    function setDebtAuctionMKRAmount(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-dump-precision"
        setValue(vow(), "dump", _amount * WAD);
    }
    /**
        @dev Set minimum bid increase for debt auctions. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setMinDebtAuctionBidIncrease(uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-flop-beg-precision"
        setValue(flop(), "beg", WAD + wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }
    /**
        @dev Set bid duration for debt auctions.
        @param _duration Amount of time for bids. (seconds)
    */
    function setDebtAuctionBidDuration(uint256 _duration) public {
        require(_duration < type(uint48).max);  // "LibDssExec/incorrect-flop-ttl-precision"
        setValue(flop(), "ttl", _duration);
    }
    /**
        @dev Set total auction duration for debt auctions.
        @param _duration Amount of time for auctions. (seconds)
    */
    function setDebtAuctionDuration(uint256 _duration) public {
        require(_duration < type(uint48).max);  // "LibDssExec/incorrect-flop-tau-precision"
        setValue(flop(), "tau", _duration);
    }
    /**
        @dev Set the rate of increasing amount of MKR out for auction during debt auctions. Amount will be converted to the correct internal precision.
        @dev MKR amount is increased by this rate every "tick" (if auction duration has passed and no one has bid on the MKR)
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setDebtAuctionMKRIncreaseRate(uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-flop-pad-precision"
        setValue(flop(), "pad", WAD + wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }
    /**
        @dev Set the maximum total DAI amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 250,000 DAI amount == 250000)
    */
    function setMaxTotalDAILiquidationAmount(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-dog-Hole-precision"
        setValue(dog(), "Hole", _amount * RAD);
    }
    /**
        @dev (LIQ 1.2) Set the maximum total DAI amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 250,000 DAI amount == 250000)
    */
    function setMaxTotalDAILiquidationAmountLEGACY(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-cat-box-amount"
        setValue(cat(), "box", _amount * RAD);
    }
    /**
        @dev Set the duration of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
        @param _duration Time in seconds to set for ES processing time
    */
    function setEmergencyShutdownProcessingTime(uint256 _duration) public {
        setValue(end(), "wait", _duration);
    }
    /**
        @dev Set the global stability fee (is not typically used, currently is 0).
            Many of the settings that change weekly rely on the rate accumulator
            described at https://docs.makerdao.com/smart-contract-modules/rates-module
            To check this yourself, use the following rate calculation (example 8%):

            $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'

            A table of rates can also be found at:
            https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setGlobalStabilityFee(uint256 _rate) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT));  // "LibDssExec/global-stability-fee-out-of-bounds"
        setValue(jug(), "base", _rate);
    }
    /**
        @dev Set the value of DAI in the reference asset (e.g. $1 per DAI). Value will be converted to the correct internal precision.
        @dev Equation used for conversion is value * RAY / 1000
        @param _value The value to set as integer (x1000) (ex. $1.025 == 1025)
    */
    function setDAIReferenceValue(uint256 _value) public {
        require(_value < WAD);  // "LibDssExec/incorrect-par-precision"
        setValue(spotter(), "par", rdiv(_value, 1000));
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    /**
        @dev Set a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        setValue(vat(), _ilk, "line", _amount * RAD);
    }
    /**
        @dev Increase a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to increase in DAI (ex. 10m DAI amount == 10000000)
        @param _global If true, increases the global debt ceiling by _amount
    */
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        address _vat = vat();
        (,,,uint256 line_,) = DssVat(_vat).ilks(_ilk);
        setValue(_vat, _ilk, "line", line_ + _amount * RAD);
        if (_global) { increaseGlobalDebtCeiling(_amount); }
    }
    /**
        @dev Decrease a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to decrease in DAI (ex. 10m DAI amount == 10000000)
        @param _global If true, decreases the global debt ceiling by _amount
    */
    function decreaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        address _vat = vat();
        (,,,uint256 line_,) = DssVat(_vat).ilks(_ilk);
        setValue(_vat, _ilk, "line", line_ - _amount * RAD);
        if (_global) { decreaseGlobalDebtCeiling(_amount); }
    }
    /**
        @dev Set a RWA collateral debt ceiling by specifying its new oracle price.
        @param _ilk      The ilk to update (ex. bytes32("ETH-A"))
        @param _ceiling  The new debt ceiling in natural units (e.g. set 10m DAI as 10_000_000)
        @param _price    The new oracle price in natural units
        @dev note: _price should enable DAI to be drawn over the loan period while taking into
                   account the configured ink amount, interest rate and liquidation ratio
        @dev note: _price * WAD should be greater than or equal to the current oracle price
    */
    function setRWAIlkDebtCeiling(bytes32 _ilk, uint256 _ceiling, uint256 _price) public {
        require(_price < WAD);
        setIlkDebtCeiling(_ilk, _ceiling);
        RwaOracleLike(getChangelogAddress("MIP21_LIQUIDATION_ORACLE")).bump(_ilk, _price * WAD);
        updateCollateralPrice(_ilk);
    }
    /**
        @dev Set the parameters for an ilk in the "MCD_IAM_AUTO_LINE" auto-line
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The Maximum value (ex. 100m DAI amount == 100000000)
        @param _gap    The amount of Dai per step (ex. 5m Dai == 5000000)
        @param _ttl    The amount of time (in seconds)
    */
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-auto-line-amount-precision"
        require(_gap < WAD);  // "LibDssExec/incorrect-auto-line-gap-precision"
        IAMLike(autoLine()).setIlk(_ilk, _amount * RAD, _gap * RAD, _ttl);
    }
    /**
        @dev Set the debt ceiling for an ilk in the "MCD_IAM_AUTO_LINE" auto-line without updating the time values
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The Maximum value (ex. 100m DAI amount == 100000000)
    */
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {
        address _autoLine = autoLine();
        (, uint256 gap, uint48 ttl,,) = IAMLike(_autoLine).ilks(_ilk);
        require(gap != 0 && ttl != 0);  // "LibDssExec/auto-line-not-configured"
        IAMLike(_autoLine).setIlk(_ilk, _amount * RAD, uint256(gap), uint256(ttl));
    }
    /**
        @dev Remove an ilk in the "MCD_IAM_AUTO_LINE" auto-line
        @param _ilk    The ilk to remove (ex. bytes32("ETH-A"))
    */
    function removeIlkFromAutoLine(bytes32 _ilk) public {
        IAMLike(autoLine()).remIlk(_ilk);
    }
    /**
        @dev Set a collateral minimum vault amount. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMinVaultAmount(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-dust-precision"
        (,, uint256 _hole,) = DogLike(dog()).ilks(_ilk);
        require(_amount <= _hole / RAD);  // Ensure ilk.hole >= dust
        setValue(vat(), _ilk, "dust", _amount * RAD);
        (bool ok,) = clip(_ilk).call(abi.encodeWithSignature("upchost()")); ok;
    }
    /**
        @dev Set a collateral liquidation penalty. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 10.25% = 10.25 * 100 = 1025)
    */
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-ilk-chop-precision"
        setValue(dog(), _ilk, "chop", WAD + wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
        (bool ok,) = clip(_ilk).call(abi.encodeWithSignature("upchost()")); ok;
    }
    /**
        @dev Set max DAI amount for liquidation per vault for collateral. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-hole-precision"
        setValue(dog(), _ilk, "hole", _amount * RAD);
    }
    /**
        @dev Set a collateral liquidation ratio. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is pct * RAY / 10,000
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 150% = 150 * 100 = 15000)
    */
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < 10 * BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-ilk-mat-precision" // Fails if pct >= 1000%
        require(_pct_bps >= BPS_ONE_HUNDRED_PCT); // the liquidation ratio has to be bigger or equal to 100%
        setValue(spotter(), _ilk, "mat", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }
    /**
        @dev Set an auction starting multiplier. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is pct * RAY / 10,000
        @param _ilk      The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps  The pct, in basis points, to set in integer form (x100). (ex. 1.3x starting multiplier = 130% = 13000)
    */
    function setStartingPriceMultiplicativeFactor(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < 10 * BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-ilk-mat-precision" // Fails if gt 10x
        require(_pct_bps >= BPS_ONE_HUNDRED_PCT); // fail if start price is less than OSM price
        setValue(clip(_ilk), "buf", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /**
        @dev Set the amout of time before an auction resets.
        @param _ilk      The ilk to update (ex. bytes32("ETH-A"))
        @param _duration Amount of time before auction resets (in seconds).
    */
    function setAuctionTimeBeforeReset(bytes32 _ilk, uint256 _duration) public {
        setValue(clip(_ilk), "tail", _duration);
    }

    /**
        @dev Percentage drop permitted before auction reset
        @param _ilk     The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps The pct, in basis points, of drop to permit (x100).
    */
    function setAuctionPermittedDrop(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-clip-cusp-value"
        setValue(clip(_ilk), "cusp", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /**
        @dev Percentage of tab to suck from vow to incentivize keepers. Amount will be converted to the correct internal precision.
        @param _ilk     The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps The pct, in basis points, of the tab to suck. (0.01% == 1)
    */
    function setKeeperIncentivePercent(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-clip-chip-precision"
        setValue(clip(_ilk), "chip", wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /**
        @dev Set max DAI amount for flat rate keeper incentive. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 1000 DAI amount == 1000)
    */
    function setKeeperIncentiveFlatRate(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD); // "LibDssExec/incorrect-clip-tip-precision"
        setValue(clip(_ilk), "tip", _amount * RAD);
    }

    /**
        @dev Sets the circuit breaker price tolerance in the clipper mom.
            This is somewhat counter-intuitive,
             to accept a 25% price drop, use a value of 75%
        @param _clip    The clipper to set the tolerance for
        @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setLiquidationBreakerPriceTolerance(address _clip, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-clippermom-price-tolerance"
        MomLike(clipperMom()).setPriceTolerance(_clip, rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /**
        @dev Set the stability fee for a given ilk.
            Many of the settings that change weekly rely on the rate accumulator
            described at https://docs.makerdao.com/smart-contract-modules/rates-module
            To check this yourself, use the following rate calculation (example 8%):

            $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'

            A table of rates can also be found at:
            https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW

        @param _ilk    The ilk to update (ex. bytes32("ETH-A") )
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
        @param _doDrip `true` to accumulate stability fees for the collateral
    */
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT));  // "LibDssExec/ilk-stability-fee-out-of-bounds"
        address _jug = jug();
        if (_doDrip) Drippable(_jug).drip(_ilk);

        setValue(_jug, _ilk, "duty", _rate);
    }


    /*************************/
    /*** Abacus Management ***/
    /*************************/

    /**
        @dev Set the number of seconds from the start when the auction reaches zero price.
        @dev Abacus:LinearDecrease only.
        @param _calc     The address of the LinearDecrease pricing contract
        @param _duration Amount of time for auctions.
    */
    function setLinearDecrease(address _calc, uint256 _duration) public {
        setValue(_calc, "tau", _duration);
    }

    /**
        @dev Set the number of seconds for each price step.
        @dev Abacus:StairstepExponentialDecrease only.
        @param _calc     The address of the StairstepExponentialDecrease pricing contract
        @param _duration Length of time between price drops [seconds]
        @param _pct_bps Per-step multiplicative factor in basis points. (ex. 99% == 9900)
    */
    function setStairstepExponentialDecrease(address _calc, uint256 _duration, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // DssExecLib/cut-too-high
        setValue(_calc, "cut", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
        setValue(_calc, "step", _duration);
    }
    /**
        @dev Set the number of seconds for each price step. (99% cut = 1% price drop per step)
             Amounts will be converted to the correct internal precision.
        @dev Abacus:ExponentialDecrease only
        @param _calc     The address of the ExponentialDecrease pricing contract
        @param _pct_bps Per-step multiplicative factor in basis points. (ex. 99% == 9900)
    */
    function setExponentialDecrease(address _calc, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // DssExecLib/cut-too-high
        setValue(_calc, "cut", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/
    /**
        @dev Allows an oracle to read prices from its source feeds
        @param _oracle  An OSM or LP oracle contract
    */
    function whitelistOracleMedians(address _oracle) public {
        (bool ok, bytes memory data) = _oracle.call(abi.encodeWithSignature("orb0()"));
        if (ok) {
            // Token is an LP oracle
            address median0 = abi.decode(data, (address));
            addReaderToWhitelistCall(median0, _oracle);
            addReaderToWhitelistCall(OracleLike_2(_oracle).orb1(), _oracle);
        } else {
            // Standard OSM
            addReaderToWhitelistCall(OracleLike_2(_oracle).src(), _oracle);
        }
    }
    /**
        @dev Adds an address to the OSM or Median's reader whitelist, allowing the address to read prices.
        @param _oracle        Oracle Security Module (OSM) or Median core contract address
        @param _reader     Address to add to whitelist
    */
    function addReaderToWhitelist(address _oracle, address _reader) public {
        OracleLike_2(_oracle).kiss(_reader);
    }
    /**
        @dev Removes an address to the OSM or Median's reader whitelist, disallowing the address to read prices.
        @param _oracle     Oracle Security Module (OSM) or Median core contract address
        @param _reader     Address to remove from whitelist
    */
    function removeReaderFromWhitelist(address _oracle, address _reader) public {
        OracleLike_2(_oracle).diss(_reader);
    }
    /**
        @dev Adds an address to the OSM or Median's reader whitelist, allowing the address to read prices.
        @param _oracle  OSM or Median core contract address
        @param _reader  Address to add to whitelist
    */
    function addReaderToWhitelistCall(address _oracle, address _reader) public {
        (bool ok,) = _oracle.call(abi.encodeWithSignature("kiss(address)", _reader)); ok;
    }
    /**
        @dev Removes an address to the OSM or Median's reader whitelist, disallowing the address to read prices.
        @param _oracle  Oracle Security Module (OSM) or Median core contract address
        @param _reader  Address to remove from whitelist
    */
    function removeReaderFromWhitelistCall(address _oracle, address _reader) public {
        (bool ok,) = _oracle.call(abi.encodeWithSignature("diss(address)", _reader)); ok;
    }
    /**
        @dev Sets the minimum number of valid messages from whitelisted oracle feeds needed to update median price.
        @param _median     Median core contract address
        @param _minQuorum  Minimum number of valid messages from whitelisted oracle feeds needed to update median price (NOTE: MUST BE ODD NUMBER)
    */
    function setMedianWritersQuorum(address _median, uint256 _minQuorum) public {
        OracleLike_2(_median).setBar(_minQuorum);
    }
    /**
        @dev Add OSM address to OSM mom, allowing it to be frozen by governance.
        @param _osm        Oracle Security Module (OSM) core contract address
        @param _ilk        Collateral type using OSM
    */
    function allowOSMFreeze(address _osm, bytes32 _ilk) public {
        MomLike(osmMom()).setOsm(_ilk, _osm);
    }

    /*****************************/
    /*** Direct Deposit Module ***/
    /*****************************/

    /**
        @dev Sets the target rate threshold for a dai direct deposit module (d3m)
        @dev Aave: Targets the variable borrow rate
        @param _d3m     The address of the D3M contract
        @param _pct_bps Target rate in basis points. (ex. 4% == 400)
    */
    function setD3MTargetInterestRate(address _d3m, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT); // DssExecLib/bar-too-high
        setValue(_d3m, "bar", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    /**
        @dev Performs basic functions and sanity checks to add a new collateral type to the MCD system
        @param _ilk      Collateral type key code [Ex. "ETH-A"]
        @param _gem      Address of token contract
        @param _join     Address of join adapter
        @param _clip     Address of liquidation agent
        @param _calc     Address of the pricing function
        @param _pip      Address of price feed
    */
    function addCollateralBase(
        bytes32 _ilk,
        address _gem,
        address _join,
        address _clip,
        address _calc,
        address _pip
    ) public {
        // Sanity checks
        address _vat = vat();
        address _dog = dog();
        address _spotter = spotter();
        require(JoinLike(_join).vat() == _vat);     // "join-vat-not-match"
        require(JoinLike(_join).ilk() == _ilk);     // "join-ilk-not-match"
        require(JoinLike(_join).gem() == _gem);     // "join-gem-not-match"
        require(JoinLike(_join).dec() ==
                   ERC20(_gem).decimals());         // "join-dec-not-match"
        require(ClipLike(_clip).vat() == _vat);     // "clip-vat-not-match"
        require(ClipLike(_clip).dog() == _dog);     // "clip-dog-not-match"
        require(ClipLike(_clip).ilk() == _ilk);     // "clip-ilk-not-match"
        require(ClipLike(_clip).spotter() == _spotter);  // "clip-ilk-not-match"

        // Set the token PIP in the Spotter
        setContract(spotter(), _ilk, "pip", _pip);

        // Set the ilk Clipper in the Dog
        setContract(_dog, _ilk, "clip", _clip);
        // Set vow in the clip
        setContract(_clip, "vow", vow());
        // Set the pricing function for the Clipper
        setContract(_clip, "calc", _calc);

        // Init ilk in Vat & Jug
        Initializable(_vat).init(_ilk);  // Vat
        Initializable(jug()).init(_ilk);  // Jug

        // Allow ilk Join to modify Vat registry
        authorize(_vat, _join);
        // Allow ilk Join to suck dai for keepers
        authorize(_vat, _clip);
        // Allow the ilk Clipper to reduce the Dog hole on deal()
        authorize(_dog, _clip);
        // Allow Dog to kick auctions in ilk Clipper
        authorize(_clip, _dog);
        // Allow End to yank auctions in ilk Clipper
        authorize(_clip, end());
        // Authorize the ESM to execute in the clipper
        authorize(_clip, esm());

        // Add new ilk to the IlkRegistry
        RegistryLike(reg()).add(_join);
    }

    // Complete collateral onboarding logic.
    function addNewCollateral(CollateralOpts memory co) public {
        // Add the collateral to the system.
        addCollateralBase(co.ilk, co.gem, co.join, co.clip, co.calc, co.pip);
        address clipperMom_ = clipperMom();

        if (!co.isLiquidatable) {
            // Disallow Dog to kick auctions in ilk Clipper
            setValue(co.clip, "stopped", 3);
        } else {
            // Grant ClipperMom access to the ilk Clipper
            authorize(co.clip, clipperMom_);
        }

        if(co.isOSM) { // If pip == OSM
            // Allow OsmMom to access to the TOKEN OSM
            authorize(co.pip, osmMom());
            if (co.whitelistOSM) { // If median is src in OSM
                // Whitelist OSM to read the Median data (only necessary if it is the first time the token is being added to an ilk)
                whitelistOracleMedians(co.pip);
            }
            // Whitelist Spotter to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToWhitelist(co.pip, spotter());
            // Whitelist Clipper on pip
            addReaderToWhitelist(co.pip, co.clip);
            // Allow the clippermom to access the feed
            addReaderToWhitelist(co.pip, clipperMom_);
            // Whitelist End to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToWhitelist(co.pip, end());
            // Set TOKEN OSM in the OsmMom for new ilk
            allowOSMFreeze(co.pip, co.ilk);
        }
        // Increase the global debt ceiling by the ilk ceiling
        increaseGlobalDebtCeiling(co.ilkDebtCeiling);

        // Set the ilk debt ceiling
        setIlkDebtCeiling(co.ilk, co.ilkDebtCeiling);

        // Set the hole size
        setIlkMaxLiquidationAmount(co.ilk, co.maxLiquidationAmount);

        // Set the ilk dust
        setIlkMinVaultAmount(co.ilk, co.minVaultAmount);

        // Set the ilk liquidation penalty
        setIlkLiquidationPenalty(co.ilk, co.liquidationPenalty);

        // Set the ilk stability fee
        setIlkStabilityFee(co.ilk, co.ilkStabilityFee, true);

        // Set the auction starting price multiplier
        setStartingPriceMultiplicativeFactor(co.ilk, co.startingPriceFactor);

        // Set the amount of time before an auction resets.
        setAuctionTimeBeforeReset(co.ilk, co.auctionDuration);

        // Set the allowed auction drop percentage before reset
        setAuctionPermittedDrop(co.ilk, co.permittedDrop);

        // Set the ilk min collateralization ratio
        setIlkLiquidationRatio(co.ilk, co.liquidationRatio);

        // Set the price tolerance in the liquidation circuit breaker
        setLiquidationBreakerPriceTolerance(co.clip, co.breakerTolerance);

        // Set a flat rate for the keeper reward
        setKeeperIncentiveFlatRate(co.ilk, co.kprFlatReward);

        // Set the percentage of liquidation as keeper award
        setKeeperIncentivePercent(co.ilk, co.kprPctReward);

        // Update ilk spot value in Vat
        updateCollateralPrice(co.ilk);
    }

    /***************/
    /*** Payment ***/
    /***************/
    /**
        @dev Send a payment in ERC20 DAI from the surplus buffer.
        @param _target The target address to send the DAI to.
        @param _amount The amount to send in DAI (ex. 10m DAI amount == 10000000)
    */
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        DssVat(vat()).suck(vow(), address(this), _amount * RAD);
        JoinLike(daiJoin()).exit(_target, _amount * WAD);
    }

    /************/
    /*** Misc ***/
    /************/
    /**
        @dev Initiate linear interpolation on an administrative value over time.
        @param _name        The label for this lerp instance
        @param _target      The target contract
        @param _what        The target parameter to adjust
        @param _startTime   The time for this lerp
        @param _start       The start value for the target parameter
        @param _end         The end value for the target parameter
        @param _duration    The duration of the interpolation
    */
    function linearInterpolation(bytes32 _name, address _target, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {
        address lerp = LerpFactoryLike(lerpFab()).newLerp(_name, _target, _what, _startTime, _start, _end, _duration);
        Authorizable(_target).rely(lerp);
        LerpLike(lerp).tick();
        return lerp;
    }
    /**
        @dev Initiate linear interpolation on an administrative value over time.
        @param _name        The label for this lerp instance
        @param _target      The target contract
        @param _ilk         The ilk to target
        @param _what        The target parameter to adjust
        @param _startTime   The time for this lerp
        @param _start       The start value for the target parameter
        @param _end         The end value for the target parameter
        @param _duration    The duration of the interpolation
    */
    function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {
        address lerp = LerpFactoryLike(lerpFab()).newIlkLerp(_name, _target, _ilk, _what, _startTime, _start, _end, _duration);
        Authorizable(_target).rely(lerp);
        LerpLike(lerp).tick();
        return lerp;
    }
}

////// lib/dss-exec-lib/src/DssAction.sol
//
// DssAction.sol -- DSS Executive Spell Actions
//
// Copyright (C) 2020-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity ^0.8.16; */

/* import { DssExecLib } from "./DssExecLib.sol"; */
/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface OracleLike_1 {
    function src() external view returns (address);
}

abstract contract DssAction {

    using DssExecLib for *;

    // Modifier used to limit execution time when office hours is enabled
    modifier limited {
        require(DssExecLib.canCast(uint40(block.timestamp), officeHours()), "Outside office hours");
        _;
    }

    // Office Hours defaults to true by default.
    //   To disable office hours, override this function and
    //    return false in the inherited action.
    function officeHours() public view virtual returns (bool) {
        return true;
    }

    // DssExec calls execute. We limit this function subject to officeHours modifier.
    function execute() external limited {
        actions();
    }

    // DssAction developer must override `actions()` and place all actions to be called inside.
    //   The DssExec function will call this subject to the officeHours limiter
    //   By keeping this function public we allow simulations of `execute()` on the actions outside of the cast time.
    function actions() public virtual;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view virtual returns (string memory);

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external view returns (uint256 castTime) {
        require(eta <= type(uint40).max);
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
    }
}

////// lib/dss-exec-lib/src/DssExec.sol
//
// DssExec.sol -- MakerDAO Executive Spell Template
//
// Copyright (C) 2020-2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity ^0.8.16; */

interface PauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface Changelog {
    function getAddress(bytes32) external view returns (address);
}

interface SpellAction {
    function officeHours() external view returns (bool);
    function description() external view returns (string memory);
    function nextCastTime(uint256) external view returns (uint256);
}

contract DssExec {

    Changelog      constant public log   = Changelog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                 public eta;
    bytes                   public sig;
    bool                    public done;
    bytes32       immutable public tag;
    address       immutable public action;
    uint256       immutable public expiration;
    PauseAbstract immutable public pause;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external view returns (string memory) {
        return SpellAction(action).description();
    }

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellAction(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. block.timestamp + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) {
        pause       = PauseAbstract(log.getAddress("MCD_PAUSE"));
        expiration  = _expiration;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;                    // Required for assembly access
        address _action = _spellAction;  // Required for assembly access
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(block.timestamp <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = block.timestamp + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

////// lib/dss-test/lib/dss-interfaces/src/ERC/GemAbstract.sol
/* pragma solidity >=0.5.12; */

// A base ERC-20 abstract class
// https://eips.ethereum.org/EIPS/eip-20
interface GemAbstract {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSAuthorityAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-auth
interface DSAuthorityAbstract {
    function canCall(address, address, bytes4) external view returns (bool);
}

interface DSAuthAbstract {
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSChiefAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-chief
interface DSChiefAbstract {
    function live() external view returns (uint256);
    function launch() external;
    function slates(bytes32) external view returns (address[] memory);
    function votes(address) external view returns (bytes32);
    function approvals(address) external view returns (uint256);
    function deposits(address) external view returns (address);
    function GOV() external view returns (address);
    function IOU() external view returns (address);
    function hat() external view returns (address);
    function MAX_YAYS() external view returns (uint256);
    function lock(uint256) external;
    function free(uint256) external;
    function etch(address[] calldata) external returns (bytes32);
    function vote(address[] calldata) external returns (bytes32);
    function vote(bytes32) external;
    function lift(address) external;
    function setOwner(address) external;
    function setAuthority(address) external;
    function isUserRoot(address) external view returns (bool);
    function setRootUser(address, bool) external;
    function _root_users(address) external view returns (bool);
    function _user_roles(address) external view returns (bytes32);
    function _capability_roles(address, bytes4) external view returns (bytes32);
    function _public_capabilities(address, bytes4) external view returns (bool);
    function getUserRoles(address) external view returns (bytes32);
    function getCapabilityRoles(address, bytes4) external view returns (bytes32);
    function isCapabilityPublic(address, bytes4) external view returns (bool);
    function hasUserRole(address, uint8) external view returns (bool);
    function canCall(address, address, bytes4) external view returns (bool);
    function setUserRole(address, uint8, bool) external;
    function setPublicCapability(address, bytes4, bool) external;
    function setRoleCapability(uint8, address, bytes4, bool) external;
}

interface DSChiefFabAbstract {
    function newChief(address, uint256) external returns (address);
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSPauseAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
    function setDelay(uint256) external;
    function plans(bytes32) external view returns (bool);
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function drop(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSPauseProxyAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseProxyAbstract {
    function owner() external view returns (address);
    function exec(address, bytes calldata) external returns (bytes memory);
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSRolesAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-roles
interface DSRolesAbstract {
    function _root_users(address) external view returns (bool);
    function _user_roles(address) external view returns (bytes32);
    function _capability_roles(address, bytes4) external view returns (bytes32);
    function _public_capabilities(address, bytes4) external view returns (bool);
    function getUserRoles(address) external view returns (bytes32);
    function getCapabilityRoles(address, bytes4) external view returns (bytes32);
    function isUserRoot(address) external view returns (bool);
    function isCapabilityPublic(address, bytes4) external view returns (bool);
    function hasUserRole(address, uint8) external view returns (bool);
    function canCall(address, address, bytes4) external view returns (bool);
    function setRootUser(address, bool) external;
    function setUserRole(address, uint8, bool) external;
    function setPublicCapability(address, bytes4, bool) external;
    function setRoleCapability(uint8, address, bytes4, bool) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSRuneAbstract.sol

// Copyright (C) 2020 Maker Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-spellbook
interface DSRuneAbstract {
    // @return [address] A contract address conforming to DSPauseAbstract
    function pause()    external view returns (address);
    // @return [address] The address of the contract to be executed
    // TODO: is `action()` a required field? Not all spells rely on a seconary contract.
    function action()   external view returns (address);
    // @return [bytes32] extcodehash of rune address
    function tag()      external view returns (bytes32);
    // @return [bytes] The `abi.encodeWithSignature()` result of the function to be called.
    function sig()      external view returns (bytes memory);
    // @return [uint256] Earliest time rune can execute
    function eta()      external view returns (uint256);
    // The schedule() function plots the rune in the DSPause
    function schedule() external;
    // @return [bool] true if the rune has been cast()
    function done()     external view returns (bool);
    // The cast() function executes the rune
    function cast()     external;
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSSpellAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-spell
interface DSSpellAbstract {
    function whom() external view returns (address);
    function mana() external view returns (uint256);
    function data() external view returns (bytes memory);
    function done() external view returns (bool);
    function cast() external;
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSThingAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-thing
interface DSThingAbstract {
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSTokenAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-token/blob/master/src/token.sol
interface DSTokenAbstract {
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function approve(address) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function mint(uint256) external;
    function mint(address,uint) external;
    function burn(uint256) external;
    function burn(address,uint) external;
    function setName(bytes32) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dapp/DSValueAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-value/blob/master/src/value.sol
interface DSValueAbstract {
    function has() external view returns (bool);
    function val() external view returns (bytes32);
    function peek() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function poke(bytes32) external;
    function void() external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/AuthGemJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-deploy/blob/master/src/join.sol
interface AuthGemJoinAbstract {
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/CatAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/cat.sol
interface CatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function box() external view returns (uint256);
    function litter() external view returns (uint256);
    function ilks(bytes32) external view returns (address, uint256, uint256);
    function live() external view returns (uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
    function bite(bytes32, address) external returns (uint256);
    function claw(uint256) external;
    function cage() external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/ChainlogAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-chain-log
interface ChainlogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function keys() external view returns (bytes32[] memory);
    function version() external view returns (string memory);
    function ipfs() external view returns (string memory);
    function setVersion(string calldata) external;
    function setSha256sum(string calldata) external;
    function setIPFS(string calldata) external;
    function setAddress(bytes32,address) external;
    function removeAddress(bytes32) external;
    function count() external view returns (uint256);
    function get(uint256) external view returns (bytes32,address);
    function list() external view returns (bytes32[] memory);
    function getAddress(bytes32) external view returns (address);
}

// Helper function for returning address or abstract of Chainlog
//  Valid on Mainnet, Kovan, Rinkeby, Ropsten, and Goerli
contract ChainlogHelper {
    address          public constant ADDRESS  = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    ChainlogAbstract public constant ABSTRACT = ChainlogAbstract(ADDRESS);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/ClipAbstract.sol

/// ClipAbstract.sol -- Clip Interface

// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.12; */

interface ClipAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilk() external view returns (bytes32);
    function vat() external view returns (address);
    function dog() external view returns (address);
    function vow() external view returns (address);
    function spotter() external view returns (address);
    function calc() external view returns (address);
    function buf() external view returns (uint256);
    function tail() external view returns (uint256);
    function cusp() external view returns (uint256);
    function chip() external view returns (uint64);
    function tip() external view returns (uint192);
    function chost() external view returns (uint256);
    function kicks() external view returns (uint256);
    function active(uint256) external view returns (uint256);
    function sales(uint256) external view returns (uint256,uint256,uint256,address,uint96,uint256);
    function stopped() external view returns (uint256);
    function file(bytes32,uint256) external;
    function file(bytes32,address) external;
    function kick(uint256,uint256,address,address) external returns (uint256);
    function redo(uint256,address) external;
    function take(uint256,uint256,uint256,address,bytes calldata) external;
    function count() external view returns (uint256);
    function list() external view returns (uint256[] memory);
    function getStatus(uint256) external view returns (bool,uint256,uint256,uint256);
    function upchost() external;
    function yank(uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/ClipperMomAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/Clipper-mom/blob/master/src/ClipperMom.sol
interface ClipperMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function locked(address) external view returns (uint256);
    function tolerance(address) external view returns (uint256);
    function spotter() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
    function setPriceTolerance(address, uint256) external;
    function setBreaker(address, uint256, uint256) external;
    function tripBreaker(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/CureAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/cure.sol
interface CureAbstract {
    function wards(address) external view returns (uint256);
    function live() external view returns (uint256);
    function srcs(uint256) external view returns (address);
    function wait() external view returns (uint256);
    function when() external view returns (uint256);
    function pos(address) external view returns (uint256);
    function amt(address) external view returns (uint256);
    function loadded(address) external view returns (uint256);
    function lCount() external view returns (uint256);
    function say() external view returns (uint256);
    function tCount() external view returns (uint256);
    function list() external view returns (address[] memory);
    function tell() external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function file(bytes32, uint256) external;
    function lift(address) external;
    function drop(address) external;
    function cage() external;
    function load(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/DaiAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/DaiJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface DaiJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function dai() external view returns (address);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/DogAbstract.sol

/// DogAbstract.sol -- Dog Interface

// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.12; */

interface DogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilks(bytes32) external view returns (address,uint256,uint256,uint256);
    function vow() external view returns (address);
    function live() external view returns (uint256);
    function Hole() external view returns (uint256);
    function Dirt() external view returns (uint256);
    function file(bytes32,address) external;
    function file(bytes32,uint256) external;
    function file(bytes32,bytes32,uint256) external;
    function file(bytes32,bytes32,address) external;
    function chop(bytes32) external view returns (uint256);
    function bark(bytes32,address,address) external returns (uint256);
    function digs(bytes32,uint256) external;
    function cage() external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/DssAutoLineAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-auto-line/blob/master/src/DssAutoLine.sol
interface DssAutoLineAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilks(bytes32) external view returns (uint256,uint256,uint48,uint48,uint48);
    function setIlk(bytes32,uint256,uint256,uint256) external;
    function remIlk(bytes32) external;
    function exec(bytes32) external returns (uint256);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/DssCdpManager.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-cdp-manager/
interface DssCdpManagerAbstract {
    function vat() external view returns (address);
    function cdpi() external view returns (uint256);
    function urns(uint256) external view returns (address);
    function list(uint256) external view returns (uint256,uint256);
    function owns(uint256) external view returns (address);
    function ilks(uint256) external view returns (bytes32);
    function first(address) external view returns (uint256);
    function last(address) external view returns (uint256);
    function count(address) external view returns (uint256);
    function cdpCan(address, uint256, address) external returns (uint256);
    function urnCan(address, address) external returns (uint256);
    function cdpAllow(uint256, address, uint256) external;
    function urnAllow(address, uint256) external;
    function open(bytes32, address) external returns (uint256);
    function give(uint256, address) external;
    function frob(uint256, int256, int256) external;
    function flux(uint256, address, uint256) external;
    function flux(bytes32, uint256, address, uint256) external;
    function move(uint256, address, uint256) external;
    function quit(uint256, address) external;
    function enter(address, uint256) external;
    function shift(uint256, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/ESMAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/esm/blob/master/src/ESM.sol
interface ESMAbstract {
    function gem() external view returns (address);
    function proxy() external view returns (address);
    function wards(address) external view returns (uint256);
    function sum(address) external view returns (address);
    function Sum() external view returns (uint256);
    function min() external view returns (uint256);
    function end() external view returns (address);
    function live() external view returns (uint256);
    function revokesGovernanceAccess() external view returns (bool);
    function rely(address) external;
    function deny(address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function cage() external;
    function fire() external;
    function denyProxy(address) external;
    function join(uint256) external;
    function burn() external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/ETHJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface ETHJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function live() external view returns (uint256);
    function cage() external;
    function join(address) external payable;
    function exit(address, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/EndAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/end.sol
interface EndAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function dog() external view returns (address);
    function vow() external view returns (address);
    function pot() external view returns (address);
    function spot() external view returns (address);
    function cure() external view returns (address);
    function live() external view returns (uint256);
    function when() external view returns (uint256);
    function wait() external view returns (uint256);
    function debt() external view returns (uint256);
    function tag(bytes32) external view returns (uint256);
    function gap(bytes32) external view returns (uint256);
    function Art(bytes32) external view returns (uint256);
    function fix(bytes32) external view returns (uint256);
    function bag(address) external view returns (uint256);
    function out(bytes32, address) external view returns (uint256);
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function cage() external;
    function cage(bytes32) external;
    function skip(bytes32, uint256) external;
    function snip(bytes32, uint256) external;
    function skim(bytes32, address) external;
    function free(bytes32) external;
    function thaw() external;
    function flow(bytes32) external;
    function pack(uint256) external;
    function cash(bytes32, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/ExponentialDecreaseAbstract.sol

/// ExponentialDecreaseAbstract.sol -- Exponential Decrease Interface

// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.12; */

interface ExponentialDecreaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function cut() external view returns (uint256);
    function file(bytes32,uint256) external;
    function price(uint256,uint256) external view returns (uint256);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/FaucetAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/token-faucet/blob/master/src/RestrictedTokenFaucet.sol
interface FaucetAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function list(address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function amt(address) external view returns (uint256);
    function done(address, address) external view returns (bool);
    function gulp(address) external;
    function gulp(address, address[] calldata) external;
    function shut(address) external;
    function undo(address, address) external;
    function setAmt(address, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/FlapAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/flap.sol
interface FlapAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48);
    function vat() external view returns (address);
    function gem() external view returns (address);
    function beg() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function live() external view returns (uint256);
    function lid() external view returns (uint256);
    function fill() external view returns (uint256);
    function file(bytes32, uint256) external;
    function kick(uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function tend(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function cage(uint256) external;
    function yank(uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/FlashAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-flash/blob/master/src/flash.sol
interface FlashAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
    function dai() external view returns (address);
    function vow() external view returns (address);
    function max() external view returns (uint256);
    function toll() external view returns (uint256);
    function CALLBACK_SUCCESS() external view returns (bytes32);
    function CALLBACK_SUCCESS_VAT_DAI() external view returns (bytes32);
    function file(bytes32, uint256) external;
    function maxFlashLoan(address) external view returns (uint256);
    function flashFee(address, uint256) external view returns (uint256);
    function flashLoan(address, address, uint256, bytes calldata) external returns (bool);
    function vatDaiFlashLoan(address, uint256, bytes calldata) external returns (bool);
    function convert() external;
    function accrue() external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/FlipAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/flip.sol
interface FlipAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function vat() external view returns (address);
    function cat() external view returns (address);
    function ilk() external view returns (bytes32);
    function beg() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function file(bytes32, uint256) external;
    function kick(address, address, uint256, uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function tend(uint256, uint256, uint256) external;
    function dent(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function yank(uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/FlipperMomAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/flipper-mom/blob/master/src/FlipperMom.sol
interface FlipperMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
    function cat() external returns (address);
    function rely(address) external;
    function deny(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/FlopAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/flop.sol
interface FlopAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48);
    function vat() external view returns (address);
    function gem() external view returns (address);
    function beg() external view returns (uint256);
    function pad() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function live() external view returns (uint256);
    function vow() external view returns (address);
    function file(bytes32, uint256) external;
    function kick(address, uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function dent(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function cage() external;
    function yank(uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/GemJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/GemJoinImplementationAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-deploy/blob/master/src/join.sol
interface GemJoinImplementationAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
    function setImplementation(address, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/GemJoinManagedAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-gem-joins/blob/master/src/join-managed.sol
interface GemJoinManagedAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, address, uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/GetCdpsAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-cdp-manager/blob/master/src/GetCdps.sol
interface GetCdpsAbstract {
    function getCdpsAsc(address, address) external view returns (uint256[] memory, address[] memory, bytes32[] memory);
    function getCdpsDesc(address, address) external view returns (uint256[] memory, address[] memory, bytes32[] memory);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/ilk-registry
interface IlkRegistryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function dog() external view returns (address);
    function cat() external view returns (address);
    function spot() external view returns (address);
    function ilkData(bytes32) external view returns (
        uint96, address, address, uint8, uint96, address, address, string memory, string memory
    );
    function ilks() external view returns (bytes32[] memory);
    function ilks(uint) external view returns (bytes32);
    function add(address) external;
    function remove(bytes32) external;
    function update(bytes32) external;
    function removeAuth(bytes32) external;
    function file(bytes32, address) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, string calldata) external;
    function count() external view returns (uint256);
    function list() external view returns (bytes32[] memory);
    function list(uint256, uint256) external view returns (bytes32[] memory);
    function get(uint256) external view returns (bytes32);
    function info(bytes32) external view returns (
        string memory, string memory, uint256, uint256, address, address, address, address
    );
    function pos(bytes32) external view returns (uint256);
    function class(bytes32) external view returns (uint256);
    function gem(bytes32) external view returns (address);
    function pip(bytes32) external view returns (address);
    function join(bytes32) external view returns (address);
    function xlip(bytes32) external view returns (address);
    function dec(bytes32) external view returns (uint256);
    function symbol(bytes32) external view returns (string memory);
    function name(bytes32) external view returns (string memory);
    function put(bytes32, address, address, uint256, uint256, address, address, string calldata, string calldata) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/JugAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/jug.sol
interface JugAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (uint256, uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function base() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/LPOsmAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/univ2-lp-oracle
interface LPOsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function stopped() external view returns (uint256);
    function bud(address) external view returns (uint256);
    function dec0() external view returns (uint8);
    function dec1() external view returns (uint8);
    function orb0() external view returns (address);
    function orb1() external view returns (address);
    function wat() external view returns (bytes32);
    function hop() external view returns (uint32);
    function src() external view returns (address);
    function zzz() external view returns (uint64);
    function change(address) external;
    function step(uint256) external;
    function stop() external;
    function start() external;
    function pass() external view returns (bool);
    function poke() external;
    function peek() external view returns (bytes32, bool);
    function peep() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function link(uint256, address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/LerpAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-lerp/blob/master/src/Lerp.sol
interface LerpAbstract {
    function target() external view returns (address);
    function what() external view returns (bytes32);
    function start() external view returns (uint256);
    function end() external view returns (uint256);
    function duration() external view returns (uint256);
    function done() external view returns (bool);
    function startTime() external view returns (uint256);
    function tick() external returns (uint256);
    function ilk() external view returns (bytes32);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/LerpFactoryAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-lerp/blob/master/src/LerpFactory.sol
interface LerpFactoryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function lerps(bytes32) external view returns (address);
    function active(uint256) external view returns (address);
    function newLerp(bytes32, address, bytes32, uint256, uint256, uint256, uint256) external returns (address);
    function newIlkLerp(bytes32, address, bytes32, bytes32, uint256, uint256, uint256, uint256) external returns (address);
    function tall() external;
    function count() external view returns (uint256);
    function list() external view returns (address[] memory);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/LinearDecreaseAbstract.sol

/// LinearDecreaseAbstract.sol -- Linear Decrease Interface

// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.12; */

interface LinearDecreaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function tau() external view returns (uint256);
    function file(bytes32,uint256) external;
    function price(uint256,uint256) external view returns (uint256);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/MedianAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/median
interface MedianAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function age() external view returns (uint32);
    function wat() external view returns (bytes32);
    function bar() external view returns (uint256);
    function orcl(address) external view returns (uint256);
    function bud(address) external view returns (uint256);
    function slot(uint8) external view returns (address);
    function read() external view returns (uint256);
    function peek() external view returns (uint256, bool);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function poke(uint256[] calldata, uint256[] calldata, uint8[] calldata, bytes32[] calldata, bytes32[] calldata) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/MkrAuthorityAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/mkr-authority/blob/master/src/MkrAuthority.sol
interface MkrAuthorityAbstract {
    function root() external returns (address);
    function setRoot(address) external;
    function wards(address) external returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function canCall(address, address, bytes4) external returns (bool);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/OsmAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/osm
interface OsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function stopped() external view returns (uint256);
    function src() external view returns (address);
    function hop() external view returns (uint16);
    function zzz() external view returns (uint64);
    function bud(address) external view returns (uint256);
    function stop() external;
    function start() external;
    function change(address) external;
    function step(uint16) external;
    function void() external;
    function pass() external view returns (bool);
    function poke() external;
    function peek() external view returns (bytes32, bool);
    function peep() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/OsmMomAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/osm-mom
interface OsmMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function osms(bytes32) external view returns (address);
    function setOsm(bytes32, address) external;
    function setOwner(address) external;
    function setAuthority(address) external;
    function stop(bytes32) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/PotAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/pot.sol
interface PotAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function pie(address) external view returns (uint256);
    function Pie() external view returns (uint256);
    function dsr() external view returns (uint256);
    function chi() external view returns (uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function rho() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function cage() external;
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/PsmAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-psm/blob/master/src/psm.sol
interface PsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function gemJoin() external view returns (address);
    function dai() external view returns (address);
    function daiJoin() external view returns (address);
    function ilk() external view returns (bytes32);
    function vow() external view returns (address);
    function tin() external view returns (uint256);
    function tout() external view returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function hope(address) external;
    function nope(address) external;
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/SpotAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/spot.sol
interface SpotAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (address, uint256);
    function vat() external view returns (address);
    function par() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
    function cage() external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/StairstepExponentialDecreaseAbstract.sol

/// StairstepExponentialDecreaseAbstract.sol -- StairstepExponentialDecrease Interface

// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.5.12; */

interface StairstepExponentialDecreaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function step() external view returns (uint256);
    function cut() external view returns (uint256);
    function file(bytes32,uint256) external;
    function price(uint256,uint256) external view returns (uint256);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/VatAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/VestAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-vest/blob/master/src/DssVest.sol
interface VestAbstract {
    function TWENTY_YEARS() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function awards(uint256) external view returns (address, uint48, uint48, uint48, address, uint8, uint128, uint128);
    function ids() external view returns (uint256);
    function cap() external view returns (uint256);
    function usr(uint256) external view returns (address);
    function bgn(uint256) external view returns (uint256);
    function clf(uint256) external view returns (uint256);
    function fin(uint256) external view returns (uint256);
    function mgr(uint256) external view returns (address);
    function res(uint256) external view returns (uint256);
    function tot(uint256) external view returns (uint256);
    function rxd(uint256) external view returns (uint256);
    function file(bytes32, uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function vest(uint256) external;
    function vest(uint256, uint256) external;
    function accrued(uint256) external view returns (uint256);
    function unpaid(uint256) external view returns (uint256);
    function restrict(uint256) external;
    function unrestrict(uint256) external;
    function yank(uint256) external;
    function yank(uint256, uint256) external;
    function move(uint256, address) external;
    function valid(uint256) external view returns (bool);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/VowAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/vow.sol
interface VowAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function flapper() external view returns (address);
    function flopper() external view returns (address);
    function sin(uint256) external view returns (uint256);
    function Sin() external view returns (uint256);
    function Ash() external view returns (uint256);
    function wait() external view returns (uint256);
    function dump() external view returns (uint256);
    function sump() external view returns (uint256);
    function bump() external view returns (uint256);
    function hump() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function fess(uint256) external;
    function flog(uint256) external;
    function heal(uint256) external;
    function kiss(uint256) external;
    function flop() external returns (uint256);
    function flap() external returns (uint256);
    function cage() external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/mip21/RwaInputConduitAbstract.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
/* pragma solidity >=0.5.12; */

interface RwaInputConduitBaseAbstract {
    function dai() external view returns (address);
    function to() external view returns (address);
    function push() external;
}

// https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaInputConduit.sol
interface RwaInputConduitAbstract is RwaInputConduitBaseAbstract {
    function gov() external view returns (address);
}

// https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaInputConduit2.sol
interface RwaInputConduit2Abstract is RwaInputConduitBaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function may(address) external view returns (uint256);
    function mate(address) external;
    function hate(address) external;
}

// https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaInputConduit3.sol
interface RwaInputConduit3Abstract is RwaInputConduitBaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function may(address) external view returns (uint256);
    function mate(address) external;
    function hate(address) external;
    function psm() external view returns (address);
    function gem() external view returns (address);
    function quitTo() external view returns (address);
    function file(bytes32, address) external;
    function push(uint) external;
    function quit() external;
    function quit(uint) external;
    function yank(address, address, uint256) external;
    function expectedDaiWad(uint256) external view returns (uint256);
    function requiredGemAmt(uint256) external view returns (uint256);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/mip21/RwaJarAbstract.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/mip21-toolkit/blob/master/src/jars/RwaJar.sol
interface RwaJarAbstract {
    function daiJoin() external view returns(address);
    function dai() external view returns(address);
    function chainlog() external view returns(address);
    function void() external;
    function toss(uint256) external;
}

////// lib/dss-test/lib/dss-interfaces/src/dss/mip21/RwaLiquidationOracleAbstract.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/mip21-toolkit/blob/master/src/oracles/RwaLiquidationOracle.sol
interface RwaLiquidationOracleAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function vow() external view returns (address);
    function ilks(bytes32) external view returns(string memory, address, uint48, uint48);
    function file(bytes32, address) external;
    function init(bytes32, uint256, string calldata, uint48) external;
    function bump(bytes32, uint256) external;
    function tell(bytes32) external;
    function cure(bytes32) external;
    function cull(bytes32, address) external;
    function good(bytes32) external view returns (bool);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/mip21/RwaOutputConduitAbstract.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
/* pragma solidity >=0.5.12; */

interface RwaOutputConduitBaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function dai() external view returns (address);
    function to() external view returns (address);
    function pick(address) external;
    function push() external;
}

// https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaOutputConduit.sol
interface RwaOutputConduitAbstract is RwaOutputConduitBaseAbstract {
    function gov() external view returns (address);
    function bud(address) external view returns (uint256);
    function kiss(address) external;
    function diss(address) external;
}

// https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaOutputConduit2.sol
interface RwaOutputConduit2Abstract is RwaOutputConduitBaseAbstract {
    function may(address) external view returns (uint256);
    function mate(address) external;
    function hate(address) external;
}

// https://github.com/makerdao/mip21-toolkit/blob/master/src/conduits/RwaOutputConduit3.sol
interface RwaOutputConduit3Abstract is RwaOutputConduitBaseAbstract {
    function bud(address) external view returns (uint256);
    function kiss(address) external;
    function diss(address) external;
    function may(address) external view returns (uint256);
    function mate(address) external;
    function hate(address) external;
    function psm() external view returns (address);
    function gem() external view returns (address);
    function quitTo() external view returns (address);
    function file(bytes32, address) external;
    function push(uint) external;
    function quit() external;
    function quit(uint) external;
    function yank(address, address, uint256) external;
    function expectedGemAmt(uint256) external view returns (uint256);
    function requiredDaiWad(uint256) external view returns (uint256);
}

////// lib/dss-test/lib/dss-interfaces/src/dss/mip21/RwaUrnAbstract.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/mip21-toolkit/blob/master/src/urns/RwaUrn.sol
// https://github.com/makerdao/mip21-toolkit/blob/master/src/urns/RwaUrn2.sol
interface RwaUrnAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function vat() external view returns (address);
    function jug() external view returns (address);
    function gemJoin() external view returns (address);
    function daiJoin() external view returns (address);
    function outputConduit() external view returns (address);
    function file(bytes32, address) external;
    function lock(uint256) external;
    function draw(uint256) external;
    function wipe(uint256) external;
    function free(uint256) external;
    function quit() external;
}

////// lib/dss-test/lib/dss-interfaces/src/sai/GemPitAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/pit.sol
interface GemPitAbstract {
    function burn(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/sai/SaiMomAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/mom.sol
interface SaiMomAbstract {
    function tub() external view returns (address);
    function tap() external view returns (address);
    function vox() external view returns (address);
    function setCap(uint256) external;
    function setMat(uint256) external;
    function setTax(uint256) external;
    function setFee(uint256) external;
    function setAxe(uint256) external;
    function setTubGap(uint256) external;
    function setPip(address) external;
    function setPep(address) external;
    function setVox(address) external;
    function setTapGap(uint256) external;
    function setWay(uint256) external;
    function setHow(uint256) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/sai/SaiTapAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/tap.sol
interface SaiTapAbstract {
    function sai() external view returns (address);
    function sin() external view returns (address);
    function skr() external view returns (address);
    function vox() external view returns (address);
    function tub() external view returns (address);
    function gap() external view returns (uint256);
    function off() external view returns (bool);
    function fix() external view returns (uint256);
    function joy() external view returns (uint256);
    function woe() external view returns (uint256);
    function fog() external view returns (uint256);
    function mold(bytes32, uint256) external;
    function heal() external;
    function s2s() external returns (uint256);
    function bid(uint256) external returns (uint256);
    function ask(uint256) external returns (uint256);
    function bust(uint256) external;
    function boom(uint256) external;
    function cage(uint256) external;
    function cash(uint256) external;
    function mock(uint256) external;
    function vent() external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/sai/SaiTopAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/top.sol
interface SaiTopAbstract {
    function vox() external view returns (address);
    function tub() external view returns (address);
    function tap() external view returns (address);
    function sai() external view returns (address);
    function sin() external view returns (address);
    function skr() external view returns (address);
    function gem() external view returns (address);
    function fix() external view returns (uint256);
    function fit() external view returns (uint256);
    function caged() external view returns (uint256);
    function cooldown() external view returns (uint256);
    function era() external view returns (uint256);
    function cage() external;
    function flow() external;
    function setCooldown(uint256) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/sai/SaiTubAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/tub.sol
interface SaiTubAbstract {
    function sai() external view returns (address);
    function sin() external view returns (address);
    function skr() external view returns (address);
    function gem() external view returns (address);
    function gov() external view returns (address);
    function vox() external view returns (address);
    function pip() external view returns (address);
    function pep() external view returns (address);
    function tap() external view returns (address);
    function pit() external view returns (address);
    function axe() external view returns (uint256);
    function cap() external view returns (uint256);
    function mat() external view returns (uint256);
    function tax() external view returns (uint256);
    function fee() external view returns (uint256);
    function gap() external view returns (uint256);
    function off() external view returns (bool);
    function out() external view returns (bool);
    function fit() external view returns (uint256);
    function rho() external view returns (uint256);
    function rum() external view returns (uint256);
    function cupi() external view returns (uint256);
    function cups(bytes32) external view returns (address, uint256, uint256, uint256);
    function lad(bytes32) external view returns (address);
    function ink(bytes32) external view returns (address);
    function tab(bytes32) external view returns (uint256);
    function rap(bytes32) external returns (uint256);
    function din() external returns (uint256);
    function air() external view returns (uint256);
    function pie() external view returns (uint256);
    function era() external view returns (uint256);
    function mold(bytes32, uint256) external;
    function setPip(address) external;
    function setPep(address) external;
    function setVox(address) external;
    function turn(address) external;
    function per() external view returns (uint256);
    function ask(uint256) external view returns (uint256);
    function bid(uint256) external view returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
    function chi() external returns (uint256);
    function rhi() external returns (uint256);
    function drip() external;
    function tag() external view returns (uint256);
    function safe(bytes32) external returns (bool);
    function open() external returns (bytes32);
    function give(bytes32, address) external;
    function lock(bytes32, uint256) external;
    function free(bytes32, uint256) external;
    function draw(bytes32, uint256) external;
    function wipe(bytes32, uint256) external;
    function shut(bytes32) external;
    function bite(bytes32) external;
    function cage(uint256, uint256) external;
    function flow() external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/sai/SaiVoxAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/vox.sol
interface SaiVoxAbstract {
    function fix() external view returns (uint256);
    function how() external view returns (uint256);
    function tau() external view returns (uint256);
    function era() external view returns (uint256);
    function mold(bytes32, uint256) external;
    function par() external returns (uint256);
    function way() external returns (uint256);
    function tell(uint256) external;
    function tune(uint256) external;
    function prod() external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/utils/WardsAbstract.sol
/* pragma solidity >=0.5.12; */

interface WardsAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
}

////// lib/dss-test/lib/dss-interfaces/src/Interfaces.sol
/* pragma solidity >=0.5.12; */

/* import { GemAbstract } from "./ERC/GemAbstract.sol"; */

/* import { DSAuthorityAbstract, DSAuthAbstract } from "./dapp/DSAuthorityAbstract.sol"; */
/* import { DSChiefAbstract } from "./dapp/DSChiefAbstract.sol"; */
/* import { DSPauseAbstract } from "./dapp/DSPauseAbstract.sol"; */
/* import { DSPauseProxyAbstract } from "./dapp/DSPauseProxyAbstract.sol"; */
/* import { DSRolesAbstract } from "./dapp/DSRolesAbstract.sol"; */
/* import { DSSpellAbstract } from "./dapp/DSSpellAbstract.sol"; */
/* import { DSRuneAbstract } from "./dapp/DSRuneAbstract.sol"; */
/* import { DSThingAbstract } from "./dapp/DSThingAbstract.sol"; */
/* import { DSTokenAbstract } from "./dapp/DSTokenAbstract.sol"; */
/* import { DSValueAbstract } from "./dapp/DSValueAbstract.sol"; */

/* import { AuthGemJoinAbstract } from "./dss/AuthGemJoinAbstract.sol"; */
/* import { CatAbstract } from "./dss/CatAbstract.sol"; */
/* import { ChainlogAbstract } from "./dss/ChainlogAbstract.sol"; */
/* import { ChainlogHelper } from "./dss/ChainlogAbstract.sol"; */
/* import { ClipAbstract } from "./dss/ClipAbstract.sol"; */
/* import { ClipperMomAbstract } from "./dss/ClipperMomAbstract.sol"; */
/* import { CureAbstract } from "./dss/CureAbstract.sol"; */
/* import { DaiAbstract } from "./dss/DaiAbstract.sol"; */
/* import { DaiJoinAbstract } from "./dss/DaiJoinAbstract.sol"; */
/* import { DogAbstract } from "./dss/DogAbstract.sol"; */
/* import { DssAutoLineAbstract } from "./dss/DssAutoLineAbstract.sol"; */
/* import { DssCdpManagerAbstract } from "./dss/DssCdpManager.sol"; */
/* import { EndAbstract } from "./dss/EndAbstract.sol"; */
/* import { ESMAbstract } from "./dss/ESMAbstract.sol"; */
/* import { ETHJoinAbstract } from "./dss/ETHJoinAbstract.sol"; */
/* import { ExponentialDecreaseAbstract } from "./dss/ExponentialDecreaseAbstract.sol"; */
/* import { FaucetAbstract } from "./dss/FaucetAbstract.sol"; */
/* import { FlapAbstract } from "./dss/FlapAbstract.sol"; */
/* import { FlashAbstract } from "./dss/FlashAbstract.sol"; */
/* import { FlipAbstract } from "./dss/FlipAbstract.sol"; */
/* import { FlipperMomAbstract } from "./dss/FlipperMomAbstract.sol"; */
/* import { FlopAbstract } from "./dss/FlopAbstract.sol"; */
/* import { GemJoinAbstract } from "./dss/GemJoinAbstract.sol"; */
/* import { GemJoinImplementationAbstract } from "./dss/GemJoinImplementationAbstract.sol"; */
/* import { GemJoinManagedAbstract } from "./dss/GemJoinManagedAbstract.sol"; */
/* import { GetCdpsAbstract } from "./dss/GetCdpsAbstract.sol"; */
/* import { IlkRegistryAbstract } from "./dss/IlkRegistryAbstract.sol"; */
/* import { JugAbstract } from "./dss/JugAbstract.sol"; */
/* import { LerpAbstract } from "./dss/LerpAbstract.sol"; */
/* import { LerpFactoryAbstract } from "./dss/LerpFactoryAbstract.sol"; */
/* import { LinearDecreaseAbstract } from "./dss/LinearDecreaseAbstract.sol"; */
/* import { LPOsmAbstract } from "./dss/LPOsmAbstract.sol"; */
/* import { MkrAuthorityAbstract } from "./dss/MkrAuthorityAbstract.sol"; */
/* import { MedianAbstract } from "./dss/MedianAbstract.sol"; */
/* import { OsmAbstract } from "./dss/OsmAbstract.sol"; */
/* import { OsmMomAbstract } from "./dss/OsmMomAbstract.sol"; */
/* import { PotAbstract } from "./dss/PotAbstract.sol"; */
/* import { PsmAbstract } from "./dss/PsmAbstract.sol"; */
/* import { SpotAbstract } from "./dss/SpotAbstract.sol"; */
/* import { StairstepExponentialDecreaseAbstract } from "./dss/StairstepExponentialDecreaseAbstract.sol"; */
/* import { VatAbstract } from "./dss/VatAbstract.sol"; */
/* import { VestAbstract } from "./dss/VestAbstract.sol"; */
/* import { VowAbstract } from "./dss/VowAbstract.sol"; */

// MIP21 Abstracts
/* import {
  RwaInputConduitBaseAbstract,
  RwaInputConduitAbstract,
  RwaInputConduit2Abstract,
  RwaInputConduit3Abstract
} from "./dss/mip21/RwaInputConduitAbstract.sol"; */
/* import { RwaJarAbstract } from "./dss/mip21/RwaJarAbstract.sol"; */
/* import { RwaLiquidationOracleAbstract } from "./dss/mip21/RwaLiquidationOracleAbstract.sol"; */
/* import {
  RwaOutputConduitBaseAbstract,
  RwaOutputConduitAbstract,
  RwaOutputConduit2Abstract,
  RwaOutputConduit3Abstract
} from "./dss/mip21/RwaOutputConduitAbstract.sol"; */
/* import { RwaUrnAbstract } from "./dss/mip21/RwaUrnAbstract.sol"; */

/* import { GemPitAbstract } from "./sai/GemPitAbstract.sol"; */
/* import { SaiMomAbstract } from "./sai/SaiMomAbstract.sol"; */
/* import { SaiTapAbstract } from "./sai/SaiTapAbstract.sol"; */
/* import { SaiTopAbstract } from "./sai/SaiTopAbstract.sol"; */
/* import { SaiTubAbstract } from "./sai/SaiTubAbstract.sol"; */
/* import { SaiVoxAbstract } from "./sai/SaiVoxAbstract.sol"; */

// Partial DSS Abstracts
/* import { WardsAbstract } from "./utils/WardsAbstract.sol"; */

////// lib/dss-test/src/GodMode.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
/* pragma solidity >=0.8.0; */

/* import {
    WardsAbstract,
    DSTokenAbstract,
    DaiAbstract,
    VatAbstract
} from "dss-interfaces/Interfaces.sol"; */
/* import {Vm} from "forge-std/Vm.sol"; */

library GodMode {

    address constant public VM_ADDR = address(bytes20(uint160(uint256(keccak256('hevm cheat code')))));

    function vm() internal pure returns (Vm) {
        return Vm(VM_ADDR);
    }

    /// @dev Set the ward for `base` for the specified `target`
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setWard(address base, address target, uint256 val) internal {

        // Edge case - ward is already set
        if (WardsAbstract(base).wards(target) == val) return;

        for (int i = 0; i < 100; i++) {
            // Scan the storage for the ward storage slot
            bytes32 prevValue = vm().load(
                address(base),
                keccak256(abi.encode(target, uint256(i)))
            );
            vm().store(
                address(base),
                keccak256(abi.encode(target, uint256(i))),
                bytes32(uint256(val))
            );
            if (WardsAbstract(base).wards(target) == val) {
                // Found it
                return;
            } else {
                // Keep going after restoring the original value
                vm().store(
                    address(base),
                    keccak256(abi.encode(target, uint256(i))),
                    prevValue
                );
            }
        }

        // We have failed if we reach here
        revert("Could not give auth access");
    }

    /// @dev Set the ward for `base` for the specified `target`
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setWard(WardsAbstract base, address target, uint256 val) internal {
        setWard(address(base), target, val);
    }

    /// @dev Set the ward for `base` for the specified `target`
    /// Note this only works for contracts compiled under Solidity. Vyper contracts use a different storage structure for maps.
    /// See https://twitter.com/msolomon44/status/1420137730009300992?t=WO2052xM3AzUCL7o7Pfkow&s=19
    function setWard(VatAbstract base, address target, uint256 val) internal {
        setWard(address(base), target, val);
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    function setBalance(address token, address who, uint256 amount) internal {
        // Edge case - balance is already set for some reason
        if (DSTokenAbstract(token).balanceOf(who) == amount) return;

        for (uint256 i = 0; i < 200; i++) {
            // Scan the storage for the solidity-style balance storage slot
            {
                bytes32 prevValue = vm().load(
                    token,
                    keccak256(abi.encode(who, uint256(i)))
                );
                vm().store(
                    token,
                    keccak256(abi.encode(who, uint256(i))),
                    bytes32(amount)
                );
                if (DSTokenAbstract(token).balanceOf(who) == amount) {
                    // Found it
                    return;
                } else {
                    // Keep going after restoring the original value
                    vm().store(
                        token,
                        keccak256(abi.encode(who, uint256(i))),
                        prevValue
                    );
                }
            }

            // Vyper-style storage layout for maps
            {
                bytes32 prevValue = vm().load(
                    token,
                    keccak256(abi.encode(uint256(i), who))
                );

                vm().store(
                    token,
                    keccak256(abi.encode(uint256(i), who)),
                    bytes32(amount)
                );
                if (DSTokenAbstract(token).balanceOf(who) == amount) {
                    // Found it
                    return;
                } else {
                    // Keep going after restoring the original value
                    vm().store(
                        token,
                        keccak256(abi.encode(uint256(i), who)),
                        prevValue
                    );
                }
            }
        }

        // We have failed if we reach here
        revert("Could not give tokens");
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    function setBalance(DSTokenAbstract token, address who, uint256 amount) internal {
        setBalance(address(token), who, amount);
    }

    /// @dev Sets the balance for `who` to `amount` for `token`.
    function setBalance(DaiAbstract token, address who, uint256 amount) internal {
        setBalance(address(token), who, amount);
    }

}

////// lib/dss-test/src/MCDUser.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
/* pragma solidity >=0.8.0; */

/* import "dss-interfaces/Interfaces.sol"; */

/* import {GodMode} from "./GodMode.sol"; */
/* import {DssInstance} from "./MCD.sol"; */

/// @dev A user which can perform actions in MCD
contract MCDUser {

    using GodMode for *;

    DssInstance dss;

    constructor(
        DssInstance memory _dss
    ) {
        dss = _dss;
    }

    /// @dev Create an auction on the provided ilk
    /// @param join The gem join adapter to use
    /// @param amount The amount of gems to use as collateral
    function createAuction(
        GemJoinAbstract join,
        uint256 amount
    ) public {
        DSTokenAbstract token = DSTokenAbstract(join.gem());
        bytes32 ilk = join.ilk();

        uint256 prevBalance = token.balanceOf(address(this));
        token.setBalance(address(this), amount);
        uint256 prevAllowance = token.allowance(address(this), address(join));
        token.approve(address(join), amount);
        join.join(address(this), amount);
        token.setBalance(address(this), prevBalance);
        token.approve(address(join), prevAllowance);
        (,uint256 rate, uint256 spot,,) = dss.vat.ilks(ilk);
        uint256 art = spot * amount / rate;
        uint256 ink = amount * (10 ** (18 - token.decimals()));
        dss.vat.frob(ilk, address(this), address(this), address(this), int256(ink), int256(art));

        // Temporarily increase the liquidation threshold to liquidate this one vault then reset it
        uint256 prevWard = dss.vat.wards(address(this));
        dss.vat.setWard(address(this), 1);
        dss.vat.file(ilk, "spot", spot / 2);
        dss.dog.bark(ilk, address(this), address(this));
        dss.vat.file(ilk, "spot", spot);
        dss.vat.setWard(address(this), prevWard);
    }

}

////// lib/dss-test/src/MCD.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
/* pragma solidity >=0.8.0; */

/* import "dss-interfaces/Interfaces.sol"; */

/* import {MCDUser} from "./MCDUser.sol"; */
/* import {GodMode} from "./GodMode.sol"; */

contract DSValue {
    bool    has;
    bytes32 val;
    function peek() public view returns (bytes32, bool) {
        return (val,has);
    }
    function read() external view returns (bytes32) {
        bytes32 wut; bool haz;
        (wut, haz) = peek();
        require(haz, "haz-not");
        return wut;
    }
    function poke(bytes32 wut) external {
        val = wut;
        has = true;
    }
    function void() external {
        val = bytes32(0);
        has = false;
    }
}

struct DssInstance {
    ChainlogAbstract chainlog;
    VatAbstract vat;
    DaiJoinAbstract daiJoin;
    DaiAbstract dai;
    VowAbstract vow;
    DogAbstract dog;
    PotAbstract pot;
    JugAbstract jug;
    SpotAbstract spotter;
    EndAbstract end;
    CureAbstract cure;
    FlapAbstract flap;
    FlopAbstract flop;
    ESMAbstract esm;
}

struct DssIlkInstance {
    DSTokenAbstract gem;
    OsmAbstract pip;
    GemJoinAbstract join;
    ClipAbstract clip;
}

library MCD {

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant RAD = 10 ** 45;

    function getAddressOrNull(DssInstance memory dss, bytes32 key) internal view returns (address) {
        try dss.chainlog.getAddress(key) returns (address a) {
            return a;
        } catch {
            return address(0);
        }
    }

    function loadFromChainlog(address chainlog) internal view returns (DssInstance memory dss) {
        return loadFromChainlog(ChainlogAbstract(chainlog));
    }

    function loadFromChainlog(ChainlogAbstract chainlog) internal view returns (DssInstance memory dss) {
        dss.chainlog = chainlog;
        dss.vat = VatAbstract(getAddressOrNull(dss, "MCD_VAT"));
        dss.daiJoin = DaiJoinAbstract(getAddressOrNull(dss, "MCD_JOIN_DAI"));
        dss.dai = DaiAbstract(getAddressOrNull(dss, "MCD_DAI"));
        dss.vow = VowAbstract(getAddressOrNull(dss, "MCD_VOW"));
        dss.dog = DogAbstract(getAddressOrNull(dss, "MCD_DOG"));
        dss.pot = PotAbstract(getAddressOrNull(dss, "MCD_POT"));
        dss.jug = JugAbstract(getAddressOrNull(dss, "MCD_JUG"));
        dss.spotter = SpotAbstract(getAddressOrNull(dss, "MCD_SPOT"));
        dss.end = EndAbstract(getAddressOrNull(dss, "MCD_END"));
        dss.cure = CureAbstract(getAddressOrNull(dss, "MCD_CURE"));
        dss.flap = FlapAbstract(getAddressOrNull(dss, "MCD_FLAP"));
        dss.flop = FlopAbstract(getAddressOrNull(dss, "MCD_FLOP"));
        dss.esm = ESMAbstract(getAddressOrNull(dss, "MCD_ESM"));
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;
        for (uint256 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function getIlk(DssInstance memory dss, string memory gem, string memory variant) internal view returns (DssIlkInstance memory) {
        return DssIlkInstance(
            DSTokenAbstract(getAddressOrNull(dss, bytesToBytes32(bytes(gem)))),
            OsmAbstract(getAddressOrNull(dss, bytesToBytes32(abi.encodePacked("PIP_", gem)))),
            GemJoinAbstract(getAddressOrNull(dss, bytesToBytes32(abi.encodePacked("MCD_JOIN_", gem, "_", variant)))),
            ClipAbstract(getAddressOrNull(dss, bytesToBytes32(abi.encodePacked("MCD_CLIP_", gem, "_", variant))))
        );
    }

    /// @dev Initialize a dummy ilk with a $1 DSValue pip without liquidations
    function initIlk(
        DssInstance memory dss,
        bytes32 ilk
    ) internal {
        DSValue pip = new DSValue();
        pip.poke(bytes32(WAD));
        initIlk(dss, ilk, address(0), address(pip));
    }

    /// @dev Initialize an ilk with a $1 DSValue pip without liquidations
    function initIlk(
        DssInstance memory dss,
        bytes32 ilk,
        address join
    ) internal {
        DSValue pip = new DSValue();
        pip.poke(bytes32(WAD));
        initIlk(dss, ilk, join, address(pip));
    }

    /// @dev Initialize an ilk without liquidations
    function initIlk(
        DssInstance memory dss,
        bytes32 ilk,
        address join,
        address pip
    ) internal {
        dss.vat.init(ilk);
        dss.jug.init(ilk);

        dss.vat.rely(join);

        dss.spotter.file(ilk, "pip", pip);
        dss.spotter.file(ilk, "mat", RAY);
        dss.spotter.poke(ilk);
    }

    /// @dev Initialize an ilk with liquidations
    function initIlk(
        DssInstance memory dss,
        bytes32 ilk,
        address join,
        address pip,
        address clip,
        address clipCalc
    ) internal {
        initIlk(dss, ilk, join, pip);

        // TODO liquidations
        clip; clipCalc;
    }

    /// @dev Give who a ward on all core contracts
    function giveAdminAccess(DssInstance memory dss, address who) internal {
        if (address(dss.vat) != address(0)) GodMode.setWard(address(dss.vat), who, 1);
        if (address(dss.dai) != address(0)) GodMode.setWard(address(dss.dai), who, 1);
        if (address(dss.vow) != address(0)) GodMode.setWard(address(dss.vow), who, 1);
        if (address(dss.dog) != address(0)) GodMode.setWard(address(dss.dog), who, 1);
        if (address(dss.pot) != address(0)) GodMode.setWard(address(dss.pot), who, 1);
        if (address(dss.jug) != address(0)) GodMode.setWard(address(dss.jug), who, 1);
        if (address(dss.spotter) != address(0)) GodMode.setWard(address(dss.spotter), who, 1);
        if (address(dss.end) != address(0)) GodMode.setWard(address(dss.end), who, 1);
        if (address(dss.cure) != address(0)) GodMode.setWard(address(dss.cure), who, 1);
        if (address(dss.esm) != address(0)) GodMode.setWard(address(dss.esm), who, 1);
    }

    /// @dev Give who a ward on all core contracts to this address
    function giveAdminAccess(DssInstance memory dss) internal {
        giveAdminAccess(dss, address(this));
    }

    function newUser(DssInstance memory dss) internal returns (MCDUser) {
        return new MCDUser(dss);
    }

}

////// lib/dss-test/src/ScriptTools.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
/* pragma solidity >=0.8.0; */

/* import { VmSafe } from "forge-std/Vm.sol"; */
/* import { stdJson } from "forge-std/StdJson.sol"; */

/* import { WardsAbstract } from "dss-interfaces/Interfaces.sol"; */

/** 
 * @title Script Tools
 * @dev Contains opinionated tools used in scripts.
 */
library ScriptTools {

    VmSafe private constant vm = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));
    
    string internal constant DEFAULT_DELIMITER = ",";
    string internal constant DELIMITER_OVERRIDE = "DSSTEST_ARRAY_DELIMITER";
    string internal constant EXPORT_JSON_KEY = "EXPORTS";

    function getRootChainId() internal view returns (uint256) {
        return vm.envUint("FOUNDRY_ROOT_CHAINID");
    }

    function readInput(string memory name) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        return readInput(root, name);
    }

    function readInput(string memory root, string memory name) internal view returns (string memory) {
        string memory chainInputFolder = string(abi.encodePacked("/script/input/", vm.toString(getRootChainId()), "/"));
        return vm.readFile(string(abi.encodePacked(root, chainInputFolder, name, ".json")));
    }

    function readOutput(string memory name, uint256 timestamp) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory chainOutputFolder = string(abi.encodePacked("/script/output/", vm.toString(getRootChainId()), "/"));
        return vm.readFile(string(abi.encodePacked(root, chainOutputFolder, name, "-", vm.toString(timestamp), ".json")));
    }

    function readOutput(string memory name) internal view returns (string memory) {
        string memory root = vm.projectRoot();
        string memory chainOutputFolder = string(abi.encodePacked("/script/output/", vm.toString(getRootChainId()), "/"));
        return vm.readFile(string(abi.encodePacked(root, chainOutputFolder, name, "-latest.json")));
    }
    
    /**
     * @notice Use standard environment variables to load config.
     * @dev Will first check FOUNDRY_SCRIPT_CONFIG_TEXT for raw json text.
     *      Falls back to FOUNDRY_SCRIPT_CONFIG for a standard file definition.
     *      Finally will fall back to the given string `name`.
     * @param name The default config file to load if no environment variables are set.
     * @return config The raw json text of the config.
     */
    function loadConfig(string memory name) internal returns (string memory config) {
        config = vm.envOr("FOUNDRY_SCRIPT_CONFIG_TEXT", string(""));
        if (eq(config, "")) {
            config = readInput(vm.envOr("FOUNDRY_SCRIPT_CONFIG", name));
        }
    }
    
    /**
     * @notice Use standard environment variables to load config.
     * @dev Will first check FOUNDRY_SCRIPT_CONFIG_TEXT for raw json text.
     *      Falls back to FOUNDRY_SCRIPT_CONFIG for a standard file definition.
     *      Finally will revert if no environment variables are set.
     * @return config The raw json text of the config.
     */
    function loadConfig() internal returns (string memory config) {
        config = vm.envOr("FOUNDRY_SCRIPT_CONFIG_TEXT", string(""));
        if (eq(config, "")) {
            config = readInput(vm.envString("FOUNDRY_SCRIPT_CONFIG"));
        }
    }
    
    /**
     * @notice Use standard environment variables to load dependencies.
     * @dev Will first check FOUNDRY_SCRIPT_DEPS_TEXT for raw json text.
     *      Falls back to FOUNDRY_SCRIPT_DEPS for a standard file definition.
     *      Finally will fall back to the given string `name`.
     * @param name The default dependency file to load if no environment variables are set.
     * @return dependencies The raw json text of the dependencies.
     */
    function loadDependencies(string memory name) internal returns (string memory dependencies) {
        dependencies = vm.envOr("FOUNDRY_SCRIPT_DEPS_TEXT", string(""));
        if (eq(dependencies, "")) {
            dependencies = readOutput(vm.envOr("FOUNDRY_SCRIPT_DEPS", name));
        }
    }
    
    /**
     * @notice Use standard environment variables to load dependencies.
     * @dev Will first check FOUNDRY_SCRIPT_DEPS_TEXT for raw json text.
     *      Falls back to FOUNDRY_SCRIPT_DEPS for a standard file definition.
     *      Finally will revert if no environment variables are set.
     * @return dependencies The raw json text of the dependencies.
     */
    function loadDependencies() internal returns (string memory dependencies) {
        dependencies = vm.envOr("FOUNDRY_SCRIPT_DEPS_TEXT", string(""));
        if (eq(dependencies, "")) {
            dependencies = readOutput(vm.envString("FOUNDRY_SCRIPT_DEPS"));
        }
    }

    /**
     * @notice Used to export important contracts to higher level deploy scripts.
     *         Note waiting on Foundry to have better primitives, but roll our own for now.
     * @dev Set FOUNDRY_EXPORTS_NAME to override the name of the json file.
     * @param name The name to give the json file.
     * @param label The label of the address.
     * @param addr The address to export.
     */
    function exportContract(string memory name, string memory label, address addr) internal {
        name = vm.envOr("FOUNDRY_EXPORTS_NAME", name);
        string memory json = vm.serializeAddress(EXPORT_JSON_KEY, label, addr);
        string memory root = vm.projectRoot();
        string memory chainOutputFolder = string(abi.encodePacked("/script/output/", vm.toString(getRootChainId()), "/"));
        vm.writeJson(json, string(abi.encodePacked(root, chainOutputFolder, name, "-", vm.toString(block.timestamp), ".json")));
        if (vm.envOr("FOUNDRY_EXPORTS_OVERWRITE_LATEST", false)) {
            vm.writeJson(json, string(abi.encodePacked(root, chainOutputFolder, name, "-latest.json")));
        }
    }

    /**
     * @notice Used to export important contracts to higher level deploy scripts.
     *         Note waiting on Foundry to have better primitives, but roll our own for now.
     * @dev Requires FOUNDRY_EXPORTS_NAME to be set.
     * @param label The label of the address.
     * @param addr The address to export.
     */
    function exportContract(string memory label, address addr) internal {
        exportContract(vm.envString("FOUNDRY_EXPORTS_NAME"), label, addr);
    }

    /**
     * @notice It's common to define strings as bytes32 (such as for ilks)
     */
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory emptyStringTest = bytes(source);
        if (emptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    /**
     * @notice Convert an ilk to a chainlog key by replacing all dashes with underscores.
     *         Ex) Convert "ETH-A" to "ETH_A"
     */
    function ilkToChainlogFormat(bytes32 ilk) internal pure returns (string memory) {
        uint256 len = 0;
        for (; len < 32; len++) {
            if (uint8(ilk[len]) == 0x00) break;
        }
        bytes memory result = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            uint8 b = uint8(ilk[i]);
            if (b == 0x2d) result[i] = bytes1(0x5f);
            else result[i] = bytes1(b);
        }
        return string(result);
    }

    function eq(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    function switchOwner(address base, address deployer, address newOwner) internal {
        if (deployer == newOwner) return;
        require(WardsAbstract(base).wards(deployer) == 1, "deployer-not-authed");
        WardsAbstract(base).rely(newOwner);
        WardsAbstract(base).deny(deployer);
    }

    // Read config variable, but allow for an environment variable override

    function readUint(string memory json, string memory key, string memory envKey) internal returns (uint256) {
        return vm.envOr(envKey, stdJson.readUint(json, key));
    }

    function readUintArray(string memory json, string memory key, string memory envKey) internal returns (uint256[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readUintArray(json, key));
    }

    function readInt(string memory json, string memory key, string memory envKey) internal returns (int256) {
        return vm.envOr(envKey, stdJson.readInt(json, key));
    }

    function readIntArray(string memory json, string memory key, string memory envKey) internal returns (int256[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readIntArray(json, key));
    }

    function readBytes32(string memory json, string memory key, string memory envKey) internal returns (bytes32) {
        return vm.envOr(envKey, stdJson.readBytes32(json, key));
    }

    function readBytes32Array(string memory json, string memory key, string memory envKey) internal returns (bytes32[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readBytes32Array(json, key));
    }

    function readString(string memory json, string memory key, string memory envKey) internal returns (string memory) {
        return vm.envOr(envKey, stdJson.readString(json, key));
    }

    function readStringArray(string memory json, string memory key, string memory envKey) internal returns (string[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readStringArray(json, key));
    }

    function readAddress(string memory json, string memory key, string memory envKey) internal returns (address) {
        return vm.envOr(envKey, stdJson.readAddress(json, key));
    }

    function readAddressArray(string memory json, string memory key, string memory envKey) internal returns (address[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readAddressArray(json, key));
    }

    function readBool(string memory json, string memory key, string memory envKey) internal returns (bool) {
        return vm.envOr(envKey, stdJson.readBool(json, key));
    }

    function readBoolArray(string memory json, string memory key, string memory envKey) internal returns (bool[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readBoolArray(json, key));
    }

    function readBytes(string memory json, string memory key, string memory envKey) internal returns (bytes memory) {
        return vm.envOr(envKey, stdJson.readBytes(json, key));
    }

    function readBytesArray(string memory json, string memory key, string memory envKey) internal returns (bytes[] memory) {
        return vm.envOr(envKey, vm.envOr(DELIMITER_OVERRIDE, DEFAULT_DELIMITER), stdJson.readBytesArray(json, key));
    }

}

////// src/dependencies/dss-direct-deposit/D3MCoreInstance.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.8.0; */

struct D3MCoreInstance {
    address hub;
    address mom;
}

////// src/dependencies/dss-direct-deposit/D3MInstance.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.8.0; */

struct D3MInstance {
    address plan;
    address pool;
    address oracle;
}

////// src/dependencies/dss-direct-deposit/D3MInit.sol
// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.8.0; */

/* import "dss-interfaces/dss/DssAutoLineAbstract.sol"; */
/* import "dss-interfaces/dss/IlkRegistryAbstract.sol"; */
/* import "dss-interfaces/ERC/GemAbstract.sol"; */
/* import { DssInstance } from "dss-test/MCD.sol"; */
/* import { ScriptTools } from "dss-test/ScriptTools.sol"; */

/* import { D3MInstance } from "./D3MInstance.sol"; */
/* import { D3MCoreInstance } from "./D3MCoreInstance.sol"; */

interface AavePoolLike {
    function hub() external view returns (address);
    function dai() external view returns (address);
    function ilk() external view returns (bytes32);
    function vat() external view returns (address);
    function file(bytes32, address) external;
    function adai() external view returns (address);
    function stableDebt() external view returns (address);
    function variableDebt() external view returns (address);
}

interface AavePlanLike {
    function rely(address) external;
    function file(bytes32, uint256) external;
    function adai() external view returns (address);
    function stableDebt() external view returns (address);
    function variableDebt() external view returns (address);
    function tack() external view returns (address);
    function adaiRevision() external view returns (uint256);
}

interface ADaiLike {
    function ATOKEN_REVISION() external view returns (uint256);
}

interface CompoundPoolLike {
    function hub() external view returns (address);
    function dai() external view returns (address);
    function ilk() external view returns (bytes32);
    function vat() external view returns (address);
    function file(bytes32, address) external;
    function cDai() external view returns (address);
    function comptroller() external view returns (address);
    function comp() external view returns (address);
}

interface CompoundPlanLike {
    function rely(address) external;
    function file(bytes32, uint256) external;
    function tack() external view returns (address);
    function delegate() external view returns (address);
    function cDai() external view returns (address);
}

interface CDaiLike {
    function interestRateModel() external view returns (address);
    function implementation() external view returns (address);
}

interface D3MOracleLike_2 {
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function file(bytes32, address) external;
}

interface D3MHubLike_2 {
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
    function file(bytes32, address) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
}

interface D3MMomLike_2 {
    function setAuthority(address) external;
}

struct D3MCommonConfig {
    address hub;
    address mom;
    bytes32 ilk;
    bool existingIlk;
    uint256 maxLine;
    uint256 gap;
    uint256 ttl;
    uint256 tau;
}

struct D3MAaveConfig {
    address king;
    uint256 bar;
    address adai;
    address stableDebt;
    address variableDebt;
    address tack;
    uint256 adaiRevision;
}

struct D3MCompoundConfig {
    address king;
    uint256 barb;
    address cdai;
    address comptroller;
    address comp;
    address tack;
    address delegate;
}

// Init a D3M instance
library D3MInit {

    function initCore(
        DssInstance memory dss,
        D3MCoreInstance memory d3mCore
    ) internal {
        D3MHubLike_2 hub = D3MHubLike_2(d3mCore.hub);
        D3MMomLike_2 mom = D3MMomLike_2(d3mCore.mom);

        // Sanity checks
        require(hub.vat() == address(dss.vat), "Hub vat mismatch");
        require(hub.daiJoin() == address(dss.daiJoin), "Hub daiJoin mismatch");

        hub.file("vow", address(dss.vow));
        hub.file("end", address(dss.end));

        mom.setAuthority(dss.chainlog.getAddress("MCD_ADM"));

        dss.vat.rely(address(hub));

        dss.chainlog.setAddress("DIRECT_HUB", address(hub));
        dss.chainlog.setAddress("DIRECT_MOM", address(mom));
    }

    function _init(
        DssInstance memory dss,
        D3MInstance memory d3m,
        D3MCommonConfig memory cfg,
        address gem
    ) private {
        bytes32 ilk = cfg.ilk;
        D3MHubLike_2 hub = D3MHubLike_2(cfg.hub);
        D3MOracleLike_2 oracle = D3MOracleLike_2(d3m.oracle);

        // Sanity checks
        require(oracle.vat() == address(dss.vat), "Oracle vat mismatch");
        require(oracle.ilk() == ilk, "Oracle ilk mismatch");

        hub.file(ilk, "pool", d3m.pool);
        hub.file(ilk, "plan", d3m.plan);
        hub.file(ilk, "tau", cfg.tau);

        oracle.file("hub", address(hub));

        dss.spotter.file(ilk, "pip", address(oracle));
        dss.spotter.file(ilk, "mat", 10 ** 27);
        uint256 previousIlkLine;
        if (cfg.existingIlk) {
            (,,, previousIlkLine,) = dss.vat.ilks(ilk);
        } else {
            dss.vat.init(ilk);
            dss.jug.init(ilk);
        }
        dss.vat.file(ilk, "line", cfg.gap);
        dss.vat.file("Line", dss.vat.Line() + cfg.gap - previousIlkLine);
        DssAutoLineAbstract(dss.chainlog.getAddress("MCD_IAM_AUTO_LINE")).setIlk(
            ilk,
            cfg.maxLine,
            cfg.gap,
            cfg.ttl
        );
        dss.spotter.poke(ilk);

        IlkRegistryAbstract(dss.chainlog.getAddress("ILK_REGISTRY")).put(
            ilk,
            address(hub),
            address(gem),
            GemAbstract(gem).decimals(),
            4,
            address(oracle),
            address(0),
            GemAbstract(gem).name(),
            GemAbstract(gem).symbol()
        );

        string memory clPrefix = ScriptTools.ilkToChainlogFormat(ilk);
        dss.chainlog.setAddress(ScriptTools.stringToBytes32(string(abi.encodePacked(clPrefix, "_POOL"))), d3m.pool);
        dss.chainlog.setAddress(ScriptTools.stringToBytes32(string(abi.encodePacked(clPrefix, "_PLAN"))), d3m.plan);
        dss.chainlog.setAddress(ScriptTools.stringToBytes32(string(abi.encodePacked(clPrefix, "_ORACLE"))), d3m.oracle);
    }

    function initAave(
        DssInstance memory dss,
        D3MInstance memory d3m,
        D3MCommonConfig memory cfg,
        D3MAaveConfig memory aaveCfg
    ) internal {
        AavePlanLike plan = AavePlanLike(d3m.plan);
        AavePoolLike pool = AavePoolLike(d3m.pool);
        ADaiLike adai = ADaiLike(aaveCfg.adai);

        _init(dss, d3m, cfg, address(adai));

        // Sanity checks
        require(pool.hub() == cfg.hub, "Pool hub mismatch");
        require(pool.ilk() == cfg.ilk, "Pool ilk mismatch");
        require(pool.vat() == address(dss.vat), "Pool vat mismatch");
        require(pool.dai() == address(dss.dai), "Pool dai mismatch");
        require(pool.adai() == address(adai), "Pool adai mismatch");
        require(pool.stableDebt() == aaveCfg.stableDebt, "Pool stableDebt mismatch");
        require(pool.variableDebt() == aaveCfg.variableDebt, "Pool variableDebt mismatch");

        require(plan.adai() == address(adai), "Plan adai mismatch");
        require(plan.stableDebt() == aaveCfg.stableDebt, "Plan stableDebt mismatch");
        require(plan.variableDebt() == aaveCfg.variableDebt, "Plan variableDebt mismatch");
        require(plan.tack() == aaveCfg.tack, "Plan tack mismatch");
        require(plan.adaiRevision() == aaveCfg.adaiRevision, "Plan adaiRevision mismatch");
        require(adai.ATOKEN_REVISION() == aaveCfg.adaiRevision, "ADai adaiRevision mismatch");

        plan.rely(cfg.mom);
        pool.file("king", aaveCfg.king);
        plan.file("bar", aaveCfg.bar);
    }

    function initCompound(
        DssInstance memory dss,
        D3MInstance memory d3m,
        D3MCommonConfig memory cfg,
        D3MCompoundConfig memory compoundCfg
    ) internal {
        CompoundPlanLike plan = CompoundPlanLike(d3m.plan);
        CompoundPoolLike pool = CompoundPoolLike(d3m.pool);
        CDaiLike cdai = CDaiLike(compoundCfg.cdai);

        _init(dss, d3m, cfg, address(cdai));

        // Sanity checks
        require(pool.hub() == cfg.hub, "Pool hub mismatch");
        require(pool.ilk() == cfg.ilk, "Pool ilk mismatch");
        require(pool.vat() == address(dss.vat), "Pool vat mismatch");
        require(pool.dai() == address(dss.dai), "Pool dai mismatch");
        require(pool.comptroller() == compoundCfg.comptroller, "Pool comptroller mismatch");
        require(pool.comp() == compoundCfg.comp, "Pool comp mismatch");
        require(pool.cDai() == address(cdai), "Pool cDai mismatch");

        require(plan.tack() == compoundCfg.tack, "Plan tack mismatch");
        require(cdai.interestRateModel() == compoundCfg.tack, "CDai tack mismatch");
        require(plan.delegate() == compoundCfg.delegate, "Plan delegate mismatch");
        require(cdai.implementation() == compoundCfg.delegate, "CDai delegate mismatch");
        require(plan.cDai() == address(cdai), "Plan cDai mismatch");

        plan.rely(cfg.mom);
        pool.file("king", compoundCfg.king);
        plan.file("barb", compoundCfg.barb);
    }

}

////// src/DssSpell.sol
// SPDX-FileCopyrightText: © 2020 Dai Foundation <www.daifoundation.org>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.8.16; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

/* import { MCD } from "dss-test/MCD.sol"; */
/* import { D3MInit, D3MCommonConfig, D3MAaveConfig } from "src/dependencies/dss-direct-deposit/D3MInit.sol"; */
/* import { D3MInstance } from "src/dependencies/dss-direct-deposit/D3MInstance.sol"; */

interface VestLike {
    function restrict(uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
}

interface GemLike {
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: cast keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/54731a9e15d6da097d578d8050bec900cf7223f5/governance/votes/Executive%20Vote%20-%20February%2022%2C%202023.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2023-02-22 MakerDAO Executive Spell | Hash: 0xa3cbfacc53bcdef9863383b0a0e16bd805fb2cd9df5957a05e0bbe91373fb1b8";

    // Turn office hours on
    function officeHours() public pure override returns (bool) {
        return true;
    }

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmVp4mhhbwWGTfbh2BzwQB9eiBrQBKiqcPRZCaAxNUaar6
    //
    // uint256 internal constant X_PCT_RATE      = ;

    uint256 constant ZERO_FIVE_PCT_RATE         = 1000000000158153903837946257;
    uint256 constant ONE_SEVENTY_FIVE_PCT_RATE  = 1000000000550121712943459312;
    uint256 constant THREE_TWENTY_FIVE_PCT_RATE = 1000000001014175731521720677;

    // Tuesday, 1 March 2022 00:00:00 UTC
    uint256 constant public MAR_01_2022 = 1646092800;
    // Saturday, 1 March 2025 00:00:00 UTC
    uint256 constant public MAR_01_2025 = 1740787200;

    uint256 internal constant MILLION = 10 ** 6;
    uint256 internal constant WAD     = 10 ** 18;
    uint256 internal constant RAY     = 10 ** 27;
    uint256 internal constant RAD     = 10 ** 45;

    address internal constant AAVE_D3M_PLAN     = 0x5846Aee09298f8F3aB5D837d540232d19e5d5813;
    address internal constant AAVE_D3M_POOL     = 0x66aE0574Eb28B92c82569b293B856BB99f80F040;
    address internal constant AAVE_D3M_ORACLE   = 0x634051fbA31829E245C616e79E289f89c8B851c2;

    address internal constant AAVE_DAI_STABLE_DEBT       = 0x778A13D3eeb110A4f7bb6529F99c000119a08E92;
    address internal constant AAVE_DAI_VARIABLE_DEBT     = 0x6C3c78838c761c6Ac7bE9F59fe808ea2A6E4379d;
    address internal constant AAVE_DAI_INTEREST_STRATEGY = 0xfffE32106A68aA3eD39CcCE673B646423EEaB62a;

    address internal constant SF_IC_WALLET_0    = 0x31C01e90Edcf8602C1A18B2aE4e5A72D8DCE76bD;
    address internal constant SF_IC_WALLET_1    = 0x12b19C5857CF92AaE5e5e5ADc6350e25e4C902e9;

    GemLike  internal immutable MKR          = GemLike(DssExecLib.mkr());
    VestLike internal immutable MCD_VEST_MKR = VestLike(DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY"));

    function actions() public override {

        // ---- New Aave v2 D3M ----
        // https://vote.makerdao.com/polling/QmUMyywc#poll-detail
        // dss-direct-deposit @ e10d92ed647bfc329c04caf306988bb73ed69640

        D3MInstance memory d3m = D3MInstance({
            plan:   AAVE_D3M_PLAN,
            pool:   AAVE_D3M_POOL,
            oracle: AAVE_D3M_ORACLE
        });

        D3MCommonConfig memory cfg = D3MCommonConfig({
            hub:         DssExecLib.getChangelogAddress("DIRECT_HUB"),
            mom:         DssExecLib.getChangelogAddress("DIRECT_MOM"),
            ilk:         "DIRECT-AAVEV2-DAI",
            existingIlk: true,              // No need to re-init in vat and jug
            maxLine:     5 * MILLION * RAD, // Set line to 5 million DAI
            gap:         5 * MILLION * RAD, // Set gap to 5 million DAI
            ttl:         12 hours,          // Set ttl to 12 hours
            tau:         7 days             // Set tau to 7 days
        });

        D3MAaveConfig memory aaveCfg = D3MAaveConfig({
            king:         DssExecLib.getChangelogAddress("MCD_PAUSE_PROXY"),
            bar:          2 * RAY / 100, // Set bar to 2%
            adai:         DssExecLib.getChangelogAddress("ADAI"),
            stableDebt:   AAVE_DAI_STABLE_DEBT,
            variableDebt: AAVE_DAI_VARIABLE_DEBT,
            tack:         AAVE_DAI_INTEREST_STRATEGY,
            adaiRevision: 2
        });

        D3MInit.initAave({
            dss:     MCD.loadFromChainlog(DssExecLib.LOG),
            d3m:     d3m,
            cfg:     cfg,
            aaveCfg: aaveCfg
        });


        // ---- MOMC Parameter Changes ----
        // https://vote.makerdao.com/polling/QmUMyywc#poll-detail

        // Stability Fee Changes

        //Increase WSTETH-B Stability Fee to 0.5%
        DssExecLib.setIlkStabilityFee("WSTETH-B", ZERO_FIVE_PCT_RATE, true);

        // Reduce RETH-A Stability Fee to 0.5%
        DssExecLib.setIlkStabilityFee("RETH-A", ZERO_FIVE_PCT_RATE, true);

        // Reduce WBTC-A Stability Fee to 1.75%
        DssExecLib.setIlkStabilityFee("WBTC-A", ONE_SEVENTY_FIVE_PCT_RATE, true);

        // Reduce WBTC-B Stability Fee to 3.25%
        DssExecLib.setIlkStabilityFee("WBTC-B", THREE_TWENTY_FIVE_PCT_RATE, true);

        // line changes

        // Increase CRVV1ETHSTETH-A line to 100 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("CRVV1ETHSTETH-A", 100 * MILLION);

        // Increase RETH-A line to 10 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("RETH-A", 10 * MILLION);

        // Increase MATIC-A line to 15 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("MATIC-A", 15 * MILLION);

        // Increase DIRECT-COMPV2-DAI line to 30 million DAI
        DssExecLib.setIlkAutoLineDebtCeiling("DIRECT-COMPV2-DAI", 30 * MILLION);

        // ---- SF-001 Contributor Vesting ----

        // Increase allowance by new vesting delta
        MKR.approve(address(MCD_VEST_MKR), MKR.allowance(address(this), address(MCD_VEST_MKR)) + 435 ether);

        // Restrict: yes | Cliff: 2023-03-01 | 2022-03-01 to 2025-03-01 | 240 MKR | 0x31C01e90Edcf8602C1A18B2aE4e5A72D8DCE76bD
        MCD_VEST_MKR.restrict(
            MCD_VEST_MKR.create(
                SF_IC_WALLET_0,                             // usr
                240 ether,                                  // tot
                MAR_01_2022,                                // bgn
                MAR_01_2025 - MAR_01_2022,                  // tau
                365 days,                                   // eta
                address(0)                                  // mgr
            )
        );

        // Restrict: yes | Cliff: 2023-03-01 | 2022-03-01 to 2025-03-01 | 195 MKR | 0x12b19C5857CF92AaE5e5e5ADc6350e25e4C902e9
        MCD_VEST_MKR.restrict(
            MCD_VEST_MKR.create(
                SF_IC_WALLET_1,                             // usr
                195 ether,                                  // tot
                MAR_01_2022,                                // bgn
                MAR_01_2025 - MAR_01_2022,                  // tau
                365 days,                                   // eta
                address(0)                                  // mgr
            )
        );

        // Bump changelog
        DssExecLib.setChangelogVersion("1.14.9");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) {}
}