// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IThrowMoneyPool {
    function getname() external view returns (string memory);
    function getsymbol() external view returns (string memory);
    function jpycAmount() external view returns (uint);
    function approveJpycFromContract() external;
    function emitMoneySent(address _senderAddr,
                           string memory _message,
                           string memory _senderAlias,
                           uint _amount) external;
}

interface IThrowMoneyFactory {
    function getPool(address sender) external view returns(address);
    function newThrowMoneyPool() external returns(address);
}

interface IWithdrawConfirmationAuthority {
    function submitTransaction(
        address _from,
        address _to,
        uint _jpycAmount
    ) external returns (uint);
    function confirmTransaction(uint _txIndex) external;
    function getOwners() external view returns (address[] memory);
    function getTransactionCount() external view returns (uint);
    function getTransaction(uint _txIndex)
        external
        view
        returns (
            address to,
            uint jpyc_value,
            bool executed,
            uint numConfirmations
        );
    function getTransactions(address _requesterAddress)
        external
        view
        returns (uint[] memory txIndices);
}


// 投げ銭のスマコン
contract ThrowMoneyPool is IThrowMoneyPool {

    // 上で定義した ERC20 規格を呼び出すためのインタフェース
    IERC20 public jpyc;
    IThrowMoneyFactory public throwMoneyFactory;
    IWithdrawConfirmationAuthority public withdrawConfirmationAuthority;

    address senderPoolAddress;
    IThrowMoneyPool senderPool;

    address owner;

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
    
    constructor(address _sender, address _throwMoneyFactoryAddress, address _withdrawCAAddress) {
        owner = _sender;

        // Rinkeby Network の JPYC
        jpyc = IERC20(0xbD9c419003A36F187DAf1273FCe184e1341362C0);

        // ThrowMoneyFactory のインターフェース
        throwMoneyFactory = IThrowMoneyFactory(_throwMoneyFactoryAddress);

        withdrawConfirmationAuthority = IWithdrawConfirmationAuthority(
            _withdrawCAAddress
        );
    }

    // イベント
    event ErrorLog(string __error_message);
    event MoneySent(address indexed __senderAddr,
                    address indexed __reciveAddr,
                    string __message,
                    string __alias,
                    uint __amount);
    event withdrawRequestId(uint __txId);


    // トークン名を確認する関数
    function getname() public view returns (string memory){
        return jpyc.name();
    }

    // シンボル (JPYC) を確認する関数
    function getsymbol() public view returns (string memory){
        return jpyc.symbol();
    }

    // プールに入っている金額を確認する関数
    function jpycAmount() public view returns (uint) {
        return jpyc.balanceOf(address(this)) / 10 ** 18;
    }

    // プールからの送金を許可する関数
    function approveJpycFromContract() public {
        jpyc.approve(address(this) , jpyc.balanceOf(address(this)) );
    }

    function emitMoneySent(address _senderAddr,
                           string memory _message,
                           string memory _senderAlias,
                           uint _amount) public {
        emit MoneySent(_senderAddr, address(this), _message, _senderAlias, _amount);
    }

    // コントラストから配信者へ送金する関数
    function sendJpyc(address _reciveAddr,
                       string memory _message,
                       string memory _senderAlias,
                       uint _amount) public onlyOwner {

        // 送金額がプールされて金額以下となるようにチェック
        require(jpyc.balanceOf(address(this)) >= _amount, "Insuffucient balance on contract");

        // 送金に必要なデータが登録されているかをチェック
        require(bytes(_message).length != 0, "Need message to throw money");
        require(_amount != 0, "Need JPYC set to be greater than 0 to throw money");
        require(_reciveAddr != address(0), "Need to set reciver address to throw money");

        // プールからの送金を許可
        try jpyc.approve(address(this), _amount) {
            // プールからの送金成功時は何もしない
        } catch Error(string memory reason) {
            // プールからの送金許可失敗時にエラーを発出
            emit ErrorLog(reason);
        }

        // 配信者のプールのアドレスを取得
        senderPoolAddress = throwMoneyFactory.getPool(_reciveAddr);
        // 配信者のプールのインターフェースを作成
        senderPool = IThrowMoneyPool(senderPoolAddress);

        try jpyc.transferFrom(address(this), senderPoolAddress, _amount) {
            // 送金成功時にイベントを発出
            senderPool.emitMoneySent(owner, _message, _senderAlias, _amount);
        } catch Error(string memory reason) {
            // 送金失敗時にはエラーを発出
            emit ErrorLog(reason);
        }
        
    }

    // プールから指定の額を owner の wallet に出金する申請を発行
    function submitWithdrawRequest(uint _jpycAmount) public onlyOwner {
        require(jpyc.balanceOf(address(this)) >= _jpycAmount, "Insuffucient balance on contract");

        uint __txId = withdrawConfirmationAuthority.submitTransaction(address(this), owner, _jpycAmount);
        jpyc.approve(address(this), _jpycAmount);
        jpyc.approve(address(withdrawConfirmationAuthority), _jpycAmount);

        emit withdrawRequestId(__txId);
    }
}


// Deploy this contract after WithdrawConfirmationAuthority
contract ThrowMoneyFactory is IThrowMoneyFactory {

    mapping(address => address) pools;

    address withdrawCAAddress;

    constructor(address _withdrawCAAddress){
        withdrawCAAddress = _withdrawCAAddress;
    }

    // イベント
    event ErrorLog(string __error_message);
    event PoolCreated(address indexed __sender_address, address __pool_address);

    function getPool(address _sender) public view returns(address) {
        return pools[_sender];
    }

    function newThrowMoneyPool() public returns(address) {
        require(address(pools[msg.sender]) == address(0), "Pool already created for this wallet address");
        // 新しいプールを作成
        ThrowMoneyPool pool = new ThrowMoneyPool(msg.sender, address(this), withdrawCAAddress);
        emit PoolCreated(msg.sender, address(pool));

        pools[msg.sender] = address(pool);

        return pools[msg.sender];
    }
}


// Deploy this contract first (before ThrowMoneyFactory)
contract WithdrawConfirmationAuthority is IWithdrawConfirmationAuthority {

    // 上で定義した ERC20 規格を呼び出すためのインタフェース
    IERC20 public jpyc;

    address[] public owners;
    mapping(address => bool) public isOwner;

    uint public numConfirmationsRequired;

    struct Transaction {
        address from;
        address to;
        uint jpycAmount;
        bool executed;
        uint numConfirmations;
    }

    // mapping from requester address => tx indices
    mapping(address => uint[]) public requesterTransactionQue;

    // mapping from tx index => owner => bool
    mapping(uint => mapping(address => bool)) public isConfirmed;

    Transaction[] public transactions;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Signer is not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx index does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx index already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx index is already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired){
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "assigned invalid owner address");
            require(!isOwner[owner], "owners have a redundant address");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;

        // Rinkeby Network の JPYC
        jpyc = IERC20(0xbD9c419003A36F187DAf1273FCe184e1341362C0);
    }

    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint jpycAmount
    );
    
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint indexed txIndex);

    function submitTransaction(
        address _from,
        address _to,
        uint _jpycAmount
    ) public returns (uint) {
        uint txIndex = transactions.length;

        transactions.push(
            Transaction({
                from: _from,
                to: _to,
                jpycAmount: _jpycAmount,
                executed: false,
                numConfirmations: 0
            })
        );

        requesterTransactionQue[_to].push(txIndex);

        emit SubmitTransaction(msg.sender, txIndex, _to, _jpycAmount);

        return txIndex;
    }

    function confirmTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint _txIndex)
        public
        onlyOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "cannot execute tx"
        );

        transaction.executed = true;

        bool success = jpyc.transferFrom(transaction.from, transaction.to, transaction.jpycAmount);

        require(success, "tx failed");

        // Delete tx index from que
        for (uint i = _txIndex; i < requesterTransactionQue[transaction.to].length - 1; i++) {
            requesterTransactionQue[transaction.to][i] = requesterTransactionQue[transaction.to][i + 1];
        }
        requesterTransactionQue[transaction.to].pop();

        emit ExecuteTransaction(msg.sender, _txIndex);
    }


    function getOwners() external view returns (address[] memory){
        return owners;
    }

    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    function getTransaction(uint _txIndex)
        external
        view
        returns (
            address to,
            uint jpycAmount,
            bool executed,
            uint numConfirmations
        ) {
        Transaction storage transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.jpycAmount,
            transaction.executed,
            transaction.numConfirmations
        );
    }

    function getTransactions(address _requesterAddress)
        external
        view
        returns (uint[] memory txIndices){
            return requesterTransactionQue[_requesterAddress];
        }
}