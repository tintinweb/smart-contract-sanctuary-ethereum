/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/Common/IDB.sol
// SPDX-License-Identifier: MIT

// License-Identifier: MIT

pragma solidity ^0.8.9;

interface IDB {

    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 ttl;
        uint64 transfer;
        string name;
    }

    function DAO() external view returns (address);
    function editor() external view returns (address);
    function NFT() external view returns (address);
    function resolver() external view returns (address);
    function filter() external view returns (address);

    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function reverseRecord(address main_address) external view returns (bytes32);

    // function nodeRecord(bytes32 node) external view returns (Node memory);
    function getNodeRecord(bytes32 node) external view returns (Node memory);
    function getNodeItem(bytes32 node, bytes32 item_key) external view returns (bytes memory);
    function getNodeOwnerItem(bytes32 node, address owner, bytes32 item_key) external view returns (bytes memory);

    function setReverse(address owner, bytes32 node) external;
    function setNodeTTL(bytes32 node, uint64 ttl, bool emit_event) external;
    function emitNodeInfo(bytes32 node) external;

    function setNodeItem(bytes32 node, bytes32 item_key, bytes memory item_value) external;
    function setNodeOwnerItem(bytes32 node, address owner, bytes32 item_key, bytes memory item_value) external;
    function setNodeItemBatch(bytes32 node, bytes32[] memory item_keys, bytes[] memory item_values) external;
    function setNodeOwnerItemBatch(bytes32 node, address owner, bytes32[] memory item_keys, bytes[] memory item_values) external;

    function isNodeActive(bytes32 node) external view returns (bool);
    function isNodeExisted(bytes32 node) external view returns (bool);

    function transferNodeOwner(bytes32 node, address new_owner) external;
    function clearNode(bytes32 node) external;
    function activateSubnode(bytes32 parent, address owner, uint64 expire, uint64 ttl, string memory name, bytes memory _data) external returns (bytes32);

    function setTokenApprovals(uint256 token_id, address to) external;
    function setOperatorApprovals(address owner, address operator, bool approved) external;

    function tokenApprovals(uint256 token_id) external view returns (address);
    function operatorApprovals(address owner, address operator) external view returns (bool);

}


// File contracts/Common/Meta.sol

// License-Identifier: MIT

pragma solidity ^0.8.9;

interface ITokenReceiver {
    function receiveFT(address token, address sender, uint256 amount) external;
    function receiveGas(address token, bytes32 sender, uint256 amount) external;
}

abstract contract Meta {

    IDB public metaDB;

    mapping(address => bool) public operators;
    address[] public historyOperators;

    modifier onlyDAO {
        require(msg.sender == metaDB.DAO(), "Caller is not the MetaDAO");
        _;
    }

    modifier onlyOperator {
        require(operators[msg.sender] , "Caller is not an operator");
        _;
    }

    modifier onlyNFT {
        require(msg.sender == metaDB.NFT(), "Caller is not MetaNFT");
        _;
    }

    modifier onlyDB {
        require(msg.sender == address(metaDB), "Caller is not MetaDB");
        _;
    }

    function initApp(address db) internal {
        metaDB = IDB(db);
    }

    function setMetaDB(address db) external onlyDAO {
        metaDB = IDB(db);
    }

    function setOperator(address addr) external onlyDAO {
        bool flag = operators[addr];
        operators[addr] = !flag;
        if (!flag) {
            historyOperators.push(addr);
        }
    }

}


// File contracts/MetaInfo.sol

// License-Identifier: MIT

pragma solidity ^0.8.9;

interface ILedger {
    function income(uint64 date) external view returns (uint256);
    function historyTotalIncome() external view returns (uint256);
}

interface IField {
    function balanceOf(address account) external view returns (uint256);
    function infrastructure() external view returns (address);
    function community() external view returns (address);
    function gasBalance(bytes32 node) external view returns (uint256);
    function nodeToAddress(bytes32 node) external view returns (address, address);
}

contract MetaInfo is Meta {

    mapping(bytes32 => address) public registrars;
    uint256 public deployHeight;
    address public ledger;
    address public field;

    event RegistrarSet(bytes32 node, address registrar, string name);
    event DeployHeightSet(address db, uint256 height);
    event LedgerSet(address ledger_addr);
    event FieldSet(address field_addr);

    constructor(address _db, address _ledger, address _field) {
        initApp(_db);
        ledger = _ledger;
        field = _field;
    }

    function setRegistrar(bytes32 node, address addr) external onlyDAO {
        registrars[node] = addr;
        emit RegistrarSet(node, addr, metaDB.getNodeRecord(node).name);
    }

    function setLedger(address addr) external onlyDAO {
        ledger = addr;
        emit LedgerSet(addr);
    }

    function setField(address addr) external onlyDAO {
        field = addr;
        emit FieldSet(addr);
    }

    function setDeployHeight(uint256 height) external onlyDAO {
        deployHeight = height;
        emit DeployHeightSet(address(metaDB), height);
    }

    function getMetaInfo(bytes32[] memory node_list) external view returns (
        address _DB,
        address _DAO,
        address _NFT,
        address _resolver,
        address _filter,
        address _editor,
        address _field,
        address _ledger,
        uint256 _height,
        address[] memory _registrars
    ) {
        _registrars = new address[](node_list.length);
        for (uint256 i = 0; i <= node_list.length; i++) {
            _registrars[i] = registrars[node_list[i]];
        }

        _DB = address(metaDB);
        _DAO = metaDB.DAO();
        _NFT = metaDB.NFT();
        _resolver = metaDB.resolver();
        _filter = metaDB.filter();
        _editor = metaDB.editor();
        _field = field;
        _ledger = ledger;
        _height = deployHeight;
    }

    function today() public view returns (uint64) {
        return uint64(block.timestamp / (24 hours));
    }

    function getStatistics() external view returns (
        uint256 income_yesterday,
        uint256 income_today,
        uint256 income_total,
        uint256 total_nodes,
        uint256 infra_balance,
        uint256 community_balance
    ) {
        income_yesterday = ILedger(ledger).income(today() - 1);
        income_today = ILedger(ledger).income(today());
        income_total = ILedger(ledger).historyTotalIncome();
        total_nodes = metaDB.totalSupply();
        infra_balance = IField(field).balanceOf(IField(field).infrastructure());
        community_balance = IField(field).balanceOf(IField(field).community());
    }

    function getNodeBaseInfo(bytes32 node, bytes32[] memory keys) external view returns (
        uint256 owner_balance,
        uint256 locked_balance,
        uint256 staked_balance,
        uint256 gas_balance,
        bytes[] memory values
    ) {
        (address left, address right) = IField(field).nodeToAddress(node);
        locked_balance = IField(field).balanceOf(right);
        staked_balance = IField(field).balanceOf(left);
        owner_balance = IField(field).balanceOf(metaDB.getNodeRecord(node).owner);
        gas_balance = locked_balance + staked_balance;
        values = new bytes[](keys.length);
        for (uint256 i = 0; i <= keys.length; i++) {
            values[i] = "null"; // TODO keys & values
        }
    }

    function getNodeBaseInfo(bytes32 node) external view returns (
        uint256 owner_balance,
        uint256 locked_balance,
        uint256 staked_balance,
        uint256 gas_balance
    ) {
        (address left, address right) = IField(field).nodeToAddress(node);
        locked_balance = IField(field).balanceOf(right);
        staked_balance = IField(field).balanceOf(left);
        owner_balance = IField(field).balanceOf(metaDB.getNodeRecord(node).owner);
        gas_balance = locked_balance + staked_balance;
    }

    /*

    function getStatisticsOfOwner(address owner, uint64 date) external view returns (
        uint256 field_balance_now,
        uint256 accumulated_reward,
        uint256 accumulated_income,
        uint256 available_income_now,
        bytes32 node,
        uint64 checkin_timestamp,
        string memory full_name
    ) {

    }

    */

}