/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;


//import "../utils/Context.sol";
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


//import "@openzeppelin/contracts/access/Ownable.sol";
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


//import "./ICreatorFeePool.sol";
//---------------------------------------------
// Creator Fee Pool interface
//---------------------------------------------
interface ICreatorFeePool {
    //-----------------------------------------
    // [read] 残高取得
    //-----------------------------------------
    // ・uint256: プール(スマコン)の保有するETH(wei)
    //-----------------------------------------
    function getBalance() external view returns (uint256);

    //-----------------------------------------
    // [read] クリエーター数取得
    //-----------------------------------------
    // ・uint256: 登録クリエイター数
    //-----------------------------------------
    function getCreatorNum() external view returns (uint256);

    //-----------------------------------------
    // [read] クリエーター情報取得(登録順での位置指定)
    //-----------------------------------------
    // ・address: クリエイターアドレス
    // ・uint256: 手数料割合(重さ)
    //-----------------------------------------
    function getInfoAt( uint256 at ) external view returns (address, uint256);

    //-----------------------------------------
    // [read] 全情報取得
    //-----------------------------------------
    // ・uint256: プール残高(wei)
    // ・address[]: クリエイターアドレス配列
    // ・uint256[]: 手数料割合(重さ)配列
    //-----------------------------------------
    function getInfoAll() external view returns (uint256, address[] memory, uint256[] memory);

    //-----------------------------------------
    // [write] クリエイター登録
    //-----------------------------------------
    function addCreator( address creator, uint256 weight ) external;

    //-----------------------------------------
    // [write] クリエイター削除
    //-----------------------------------------
    function deleteCreator( address creator ) external;

    //-----------------------------------------
    // [write] 分配
    //-----------------------------------------
    function distribute() external;

}


//import "./Common/CreatorFeePool.sol";
//------------------------------------------------------------
// CreatorFeePool
//------------------------------------------------------------
contract CreatorFeePool is Ownable, ICreatorFeePool {
    //--------------------------------------
    // event
    //--------------------------------------
    event AgencyTransferred( address indexed previousAgent, address indexed newAgent );
    event CreatorWeightUpdated( address indexed creator, uint256 previousWeight, uint256 newWeight );

    //--------------------------------------------------------
    // ストレージ
    //--------------------------------------------------------
    address private _agent;             // 代理人(管理スマコンを想定)
    address[] private _arr_creator;     // クリエイター配列    
    uint256[] private _arr_weight;      // 配分率(重さ)配列

    //--------------------------------------------------------
    // [modifier] onlyOwnerOrAgent
    //--------------------------------------------------------
    modifier onlyOwnerOrAgent() {
        require( msg.sender == owner() || msg.sender == agent(), "caller is not the owner neither agent" );
        _;
    }

    //--------------------------------------------------------
    // コンストラクタ（管理スマコンから呼ばれる想定）
    //--------------------------------------------------------
    constructor( address owner ) Ownable() {
        require( owner != address(0x0), "invalid owner" );

        transferOwnership( owner );

        _agent = msg.sender;
        emit AgencyTransferred( address(0x0), _agent );
    }

    //--------------------------------------------------------
    // [external/payable] 入金を受けつける
    //--------------------------------------------------------
    receive() external payable {}

    //--------------------------------------------------------
    // [public] agent
    //--------------------------------------------------------
    function agent() public view returns (address) {
        return( _agent );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] setAgent
    //--------------------------------------------------------
    function setAgent( address target ) external onlyOwner {
        require( target != address(0x0), "invalid target" );

        address previousAgent = _agent;
        _agent = target;

        // event
        emit AgencyTransferred( previousAgent, target );
    }

    //--------------------------------------
    // [external/override] getBalance
    //--------------------------------------
    function getBalance() external view override returns (uint256) {
        return( address(this).balance );
    }

    //--------------------------------------
    // [external/override] getCreatorNum
    //--------------------------------------
    function getCreatorNum() external view override returns (uint256) {
        return( _arr_creator.length );
    }

    //--------------------------------------
    // [external/override] getInfoAt
    //--------------------------------------
    function getInfoAt( uint256 at ) external view override returns (address, uint256) {
        require( at >= 0 && at < _arr_creator.length, "invalid at" );
        return( _arr_creator[at], _arr_weight[at] );
    }

    //--------------------------------------
    // [external/override] getInfoAll
    //--------------------------------------
    function getInfoAll() external view override returns (uint256, address[] memory, uint256[] memory) {
        return( address(this).balance, _arr_creator, _arr_weight );
    }

    //--------------------------------------------------------
    // [external/override/onlyOwnerOrAgent] addCreator
    //--------------------------------------------------------
    function addCreator( address creator, uint256 weight ) external override onlyOwnerOrAgent {
        require( creator != address(0x0), "invalid address" );
        require( weight > 0, "invalid weight" );

        // 既存のアドレスなら割合の更新
        for( uint256 i=0; i<_arr_creator.length; i++ ){
            if( _arr_creator[i] == creator ){
                uint256 previousWeight = _arr_weight[i];
                _arr_weight[i] = weight;

                // event
                emit CreatorWeightUpdated( creator, previousWeight, weight );
                return;
            }
        }

        // ここまできたら新規登録
        _arr_creator.push( creator );
        _arr_weight.push( weight );

        // event
        emit CreatorWeightUpdated( creator, 0, weight );
    }

    //--------------------------------------------------------
    // [external/override/onlyOwnerOrAgent] deleteCreator
    //--------------------------------------------------------
    function deleteCreator( address creator ) external override onlyOwnerOrAgent {
        // 対象の検索
        for( uint256 i=0; i<_arr_creator.length; i++ ){
            if( _arr_creator[i] == creator ){
                uint256 previousWeight = _arr_weight[i];

                // 前詰め
                for( uint256 j=i+1; j<_arr_creator.length; j++ ){
                    _arr_creator[j-1] = _arr_creator[j];
                    _arr_weight[j-1] = _arr_weight[j];
                }

                // 末尾の削除
                _arr_creator.pop();
                _arr_weight.pop();

                // event
                emit CreatorWeightUpdated( creator, previousWeight, 0 );
                return;
            }
        }
    }

    //--------------------------------------------------------
    // [external/override] distribute（誰が呼んでも構わないい）
    //--------------------------------------------------------
    function distribute() external override {
        require( _arr_creator.length > 0, "no creator" );
        require( address(this).balance > 0, "no balance" );

        // 重みの算出
        uint256 total;
        for( uint256 i=0; i<_arr_creator.length; i++ ){
            total += _arr_weight[i];
        }

        // 転送（二人目から）
        address payable target;
        uint256 base = address(this).balance;
        for( uint256 i=1; i<_arr_creator.length; i++ ){
            uint256 amount = base * _arr_weight[i] / total;
            target = payable( _arr_creator[i] );
            target.transfer( amount );
        }

        // 転送（一人目が残りをもらう／端数残らないように）
        target = payable( _arr_creator[0] );
        target.transfer( address(this).balance );
    }

}


//------------------------------------------------------------
// CREATOR FEE DISTRIBUTOR
//------------------------------------------------------------
contract CreatorFeeDistributor is Ownable {
    //--------------------------------------
    // event
    //--------------------------------------
    event PoolDeployed( uint256 indexed poolId, address pool );
    event PoolDeleted( uint256 indexed poolId, address pool );

    //--------------------------------------------------------
    // 定数
    //--------------------------------------------------------
    address constant private OWNER_ADDRESS = 0x66d1633c03a02DE32B25dA1A98D793c1D9A9fa1D;

    //--------------------------------------------------------
    // ストレージ
    //--------------------------------------------------------
    // 管理者(複数登録可能)
    mapping( address => bool ) private _map_manager;

    // 管理するプール
    mapping( uint256 => ICreatorFeePool ) private _map_pool;

    //--------------------------------------------------------
    // [modifier] onlyOwnerOrManager
    //--------------------------------------------------------
    modifier onlyOwnerOrManager() {
        require( msg.sender == owner() || isManager(msg.sender), "caller is not the owner neither manager" );
        _;
    }

    //--------------------------------------------------------
    // コンストラクタ
    //--------------------------------------------------------
    constructor() Ownable() {
        transferOwnership( OWNER_ADDRESS );
    }

    //--------------------------------------
    // [public] マネージャーか？
    //--------------------------------------
    function isManager( address target ) public view returns (bool) {
        return( _map_manager[target] );
    }

    //--------------------------------------
    // [external/onlyOwner] マネージャー設定
    //--------------------------------------
    function setManager( address target, bool flag ) external onlyOwner {
        if( flag ){
            _map_manager[target] = true;
        }else{
            delete _map_manager[target];
        }
    }

    //--------------------------------------------------------
    // [external] プール確認
    //--------------------------------------------------------
    function pool( uint256 poolId ) external view returns (address) {
        return( address(_map_pool[poolId]) );
    }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] プールの作成（スマコンデプロイ）
    //--------------------------------------------------------
    function createPool( uint256 poolId ) external onlyOwnerOrManager {
        require( address(_map_pool[poolId]) == address(0x0), "pool already existed" );

        _map_pool[poolId] = ICreatorFeePool(new CreatorFeePool( owner() ));

        // event
        emit PoolDeployed( poolId, address(_map_pool[poolId]) );
    }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] プールの削除（リストから削除のみ）
    //--------------------------------------------------------
    function deletePool( uint256 poolId ) external onlyOwnerOrManager {
        address target = address(_map_pool[poolId]);
        require( target != address(0x0), "non existent pool" );

        delete _map_pool[poolId];

        // event
        emit PoolDeleted( poolId, target );
    }

    //-----------------------------------------
    // [external] getBalance(窓口)
    //-----------------------------------------
    function getBalance( uint256 poolId ) external view returns (uint256) {
        require( address(_map_pool[poolId]) != address(0x0), "non existent pool" );

        return( _map_pool[poolId].getBalance() );
    }

    //-----------------------------------------
    // [external] getCreatorNum(窓口)
    //-----------------------------------------
    function getCreatorNum( uint256 poolId ) external view returns (uint256) {
        require( address(_map_pool[poolId]) != address(0x0), "non existent pool" );

        return( _map_pool[poolId].getCreatorNum() );
    }

    //-----------------------------------------
    // [external] getInfoAt(窓口)
    //-----------------------------------------
    function getInfoAt( uint256 poolId, uint256 at ) external view returns (address, uint256) {
        require( address(_map_pool[poolId]) != address(0x0), "non existent pool" );

        return( _map_pool[poolId].getInfoAt( at ) );
    }

    //-----------------------------------------
    // [external] getInfoAll(窓口)
    //-----------------------------------------
    function getInfoAll( uint256 poolId ) external view returns (uint256, address[] memory, uint256[] memory) {
        require( address(_map_pool[poolId]) != address(0x0), "non existent pool" );

        return( _map_pool[poolId].getInfoAll() );
    }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] addCreators(窓口)
    //--------------------------------------------------------
    function addCreators( uint256 poolId, address[] calldata creators, uint256[] calldata weights ) external onlyOwnerOrManager {
        require( address(_map_pool[poolId]) != address(0x0), "non existent pool" );
        require( creators.length == weights.length, "array length mismatch" );

        for( uint256 i=0; i<creators.length; i++ ){
            _map_pool[poolId].addCreator( creators[i], weights[i] );
        }
    }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] deleteCreators(窓口)
    //--------------------------------------------------------
    function deleteCreators( uint256 poolId, address[] calldata creators ) external onlyOwnerOrManager {
        require( address(_map_pool[poolId]) != address(0x0), "non existent pool" );

        for( uint256 i=0; i<creators.length; i++ ){
            _map_pool[poolId].deleteCreator( creators[i] );
        }
    }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] distribute(窓口)
    //--------------------------------------------------------
    function distribute( uint256 poolId ) external onlyOwnerOrManager {
        require( address(_map_pool[poolId]) != address(0x0), "non existent pool" );

        _map_pool[poolId].distribute();
    }

}