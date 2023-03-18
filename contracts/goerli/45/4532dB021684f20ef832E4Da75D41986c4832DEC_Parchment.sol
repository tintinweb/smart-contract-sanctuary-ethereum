// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IParchment {
    enum AuthzStatus {
        WAITING,
        APPROVE,
        CANCELLED
    }
    struct AuthzApplyInfo {
        address walletAddress; // 申请者钱包地址
        string pk; // 申请者公钥
        uint256 time; // 申请时间
        AuthzStatus status; // 授权状态
        bool valid; // 标记位，用于判断申请信息是否有效
    }

    function uploadData(
        string calldata _hash,
        string calldata _kcph,
        bool _isPlaintext
    ) external;

    function viewData(
        address _owner,
        string calldata _hash
    )
        external
        view
        returns (string memory kcph, string memory hash, bool isPlaintext);

    function applyData(
        address _owner,
        string calldata _hash,
        string calldata _pk
    ) external;

    function authzData(
        address _to,
        string calldata _hash,
        string calldata _rkcph
    ) external;

    function cancelAuthzData(address _to, string calldata _hash) external;

    function listApplyRecord(
        string calldata _hash
    ) external view returns (AuthzApplyInfo[] memory);

    function listOwnedData() external view returns (string[] memory hashlist);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

import "./IParchment.sol";

contract Parchment is IParchment {
    struct Data {
        string hash; // 数据明文的哈希值
        string kcph; // 使用 Pa 加密的 k 和 addr
        bool isPlaintext; // 是否是明文存储
        bool valid; // 标记位，用于判断数据是否有效
    }

    struct ReEncryptData {
        string rkcph; // 重加密数据
        bool valid; // 标记位，用于判断重加密数据是否有效
    }

    // 全量数据：数据拥有者 => (数据哈希 => 数据信息)
    // mapping 用于对数据去重，string[] 用于数据遍历
    mapping(address => mapping(string => Data)) dataRecord;
    mapping(address => string[]) dataList;

    // 授权记录：数据拥有者 => (数据哈希 => (被授权用户 => 被授权数据))
    mapping(address => mapping(string => mapping(address => ReEncryptData))) authzRecord;

    // 申请信息：数据拥有者 => (数据哈希 => (申请用户 => 申请信息))
    // mapping 用于对申请者去重，string[] 用于申请记录遍历
    mapping(address => mapping(string => mapping(address => AuthzApplyInfo))) authzApplyRecord;
    mapping(address => mapping(string => address[])) authzApplyList;

    // 上传数据事件
    event UploadData(address indexed operator, string indexed hash);
    // 申请数据事件
    event ApplyData(
        address indexed operator,
        address indexed owner,
        string indexed hash
    );
    // 授权数据事件
    event AuthzData(
        address indexed operator,
        string indexed hash,
        address indexed to
    );
    // 取消授权数据事件
    event CancelAuthzData(
        address indexed operator,
        string indexed hash,
        address indexed to
    );

    error RepeatUpload(address operator, string hash); // 重复上传数据
    error NotExists(address owner, string hash); // 数据不存在
    error NotAuthorized(address visitor, address owner, string hash); // 未被授权数据
    error NotApplied(address visitor, address owner, string hash); // 未申请数据
    error IsPlaintext(address owner, string hash); // 数据明文存储

    // 保证每个用户相同的数据只能上传一次
    modifier uniqueUpload(string calldata _hash) {
        if (dataRecord[msg.sender][_hash].valid) {
            revert RepeatUpload(msg.sender, _hash);
        }
        _;
    }

    // 保证要查看的数据存在
    modifier dataExists(address _owner, string calldata _hash) {
        if (!dataRecord[_owner][_hash].valid) {
            revert NotExists(_owner, _hash);
        }
        _;
    }

    // 保证数据访问者有访问权限
    modifier ownerOrAuthorized(address _owner, string calldata _hash) {
        if (
            msg.sender != _owner &&
            !dataRecord[_owner][_hash].isPlaintext &&
            !authzRecord[_owner][_hash][msg.sender].valid
        ) {
            revert NotAuthorized(msg.sender, _owner, _hash);
        }
        _;
    }

    // 保证数据是加密存储形式
    modifier dataNotPlaintext(address _owner, string calldata _hash) {
        if (dataRecord[_owner][_hash].isPlaintext) {
            revert IsPlaintext(_owner, _hash);
        }
        _;
    }

    // 保证数据访问者已提交授权申请
    modifier dataApplied(
        address _owner,
        string calldata _hash,
        address _visitor
    ) {
        if (!authzApplyRecord[_owner][_hash][_visitor].valid) {
            revert NotApplied(_visitor, _owner, _hash);
        }
        _;
    }

    /**
     * 上传数据
     * _hash: 数据明文的哈希值
     * _kcph: 使用 Pa 加密的 k 和 addr
     * _isPlaintext: 是否是明文存储
     */
    function uploadData(
        string calldata _hash,
        string calldata _kcph,
        bool _isPlaintext
    ) external uniqueUpload(_hash) {
        dataRecord[msg.sender][_hash] = Data({
            hash: _hash,
            kcph: _kcph,
            isPlaintext: _isPlaintext,
            valid: true
        });
        dataList[msg.sender].push(_hash);

        emit UploadData(msg.sender, _hash);
    }

    /**
     * 查看数据
     * _owner: 数据拥有者
     * _hash: 数据明文的哈希值
     */
    function viewData(
        address _owner,
        string calldata _hash
    )
        external
        view
        dataExists(_owner, _hash)
        ownerOrAuthorized(_owner, _hash)
        returns (string memory kcph, string memory hash, bool isPlaintext)
    {
        Data memory data = dataRecord[_owner][_hash];
        hash = _hash;
        isPlaintext = data.isPlaintext;
        if (msg.sender == _owner || isPlaintext) {
            kcph = data.kcph;
        } else {
            kcph = authzRecord[_owner][_hash][msg.sender].rkcph;
        }
    }

    /**
     * 申请数据
     * _owner: 数据拥有者
     * _hash: 数据明文的哈希值
     * _pk: 当前数据访问者的公钥
     */
    function applyData(
        address _owner,
        string calldata _hash,
        string calldata _pk
    ) external dataExists(_owner, _hash) dataNotPlaintext(_owner, _hash) {
        authzApplyRecord[_owner][_hash][msg.sender] = AuthzApplyInfo({
            walletAddress: msg.sender,
            pk: _pk,
            time: block.timestamp,
            status: AuthzStatus.WAITING,
            valid: true
        });
        authzApplyList[_owner][_hash].push(msg.sender);

        emit ApplyData(msg.sender, _owner, _hash);
    }

    /**
     * 授权数据
     * _to: 被授权者地址
     * _hash: 被授权数据哈希值
     * _rkcph: 被重加密的数据
     */
    function authzData(
        address _to,
        string calldata _hash,
        string calldata _rkcph
    )
        external
        dataExists(msg.sender, _hash)
        dataApplied(msg.sender, _hash, _to)
    {
        authzRecord[msg.sender][_hash][_to] = ReEncryptData({
            rkcph: _rkcph,
            valid: true
        });

        emit AuthzData(msg.sender, _hash, _to);
    }

    /**
     * 取消授权数据
     * _to: 被授权者地址
     * _hash: 被授权数据哈希值
     */
    function cancelAuthzData(
        address _to,
        string calldata _hash
    ) external dataExists(msg.sender, _hash) ownerOrAuthorized(_to, _hash) {
        delete authzRecord[msg.sender][_hash][_to];

        emit CancelAuthzData(msg.sender, _hash, _to);
    }

    /**
     * 列出数据申请记录
     * _hash: 数据哈希值
     */
    function listApplyRecord(
        string calldata _hash
    ) external view returns (AuthzApplyInfo[] memory) {
        uint256 recordNum = authzApplyList[msg.sender][_hash].length;
        AuthzApplyInfo[] memory applyList = new AuthzApplyInfo[](recordNum);
        for (uint256 i = 0; i < recordNum; i++) {
            address addr = authzApplyList[msg.sender][_hash][i];
            applyList[i] = authzApplyRecord[msg.sender][_hash][addr];
        }
        return applyList;
    }

    /**
     * 列出拥有的数据
     */
    function listOwnedData() external view returns (string[] memory hashlist) {
        hashlist = dataList[msg.sender];
    }
}