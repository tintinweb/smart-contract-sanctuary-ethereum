/**
 *Submitted for verification at Etherscan.io on 2023-01-14
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


//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


//import "./Common/IBlockMintable.sol";
//--------------------------------------------
// BlockMintable intterface
//--------------------------------------------
interface IBlockMintable {
    //----------------
    // read
    //----------------
    function getBlockTokenIdFrom( uint256 blockId ) external view returns (uint256);
    function getBlockTokenNum( uint256 blockId ) external view returns (uint256);
    function getBlockMintable( uint256 blockId ) external view returns (address);

    //----------------
    // write
    //----------------
    function mintByMinter( uint256 tokenId, address owner ) external;
}


//------------------------------------------------------------
// Vendor01
//------------------------------------------------------------
contract Vendor01 is Ownable, ReentrancyGuard {
    //--------------------------------------------------------
    // 定数
    //--------------------------------------------------------
    address constant private OWNER_ADDRESS = 0xE524Fd8B4C262767e8577acE6343b7540Ee9B243;
    address constant private TOKEN_ADDRESS = 0x414E3956822AFcfFBBbE8DAD4141E3aa58c38E7b;
    uint256 constant private BLOCK_SEC_MARGIN = 30;
    uint256 constant private CHARA_TYPE_NUM = 12;

    // enum
    uint256 constant private INFO_SALE_SUSPENDED = 0;
    uint256 constant private INFO_SALE_SUSPENDED_RANDOM = 1;
    uint256 constant private INFO_SALE_START = 2;
    uint256 constant private INFO_SALE_END = 3;
    uint256 constant private INFO_SALE_PRICE = 4;
    uint256 constant private INFO_SALE_PRICE_RANDOM = 5;
    uint256 constant private INFO_MINT_TOKEN_MAX = 6;
    uint256 constant private INFO_MINT_CHARA_MAX = 7;
    uint256 constant private INFO_MINT_TOTAL_SUPPLY = 8;
    uint256 constant private INFO_MINT_CHARA_SUPPLY = 9;
    uint256 constant private INFO_MAX = INFO_MINT_CHARA_SUPPLY + CHARA_TYPE_NUM;

    //--------------------------------------------------------
    // 管理
    //--------------------------------------------------------
    address private _manager;

    IBlockMintable private _token_contract;
    bool private    _token_contract_enabled;

    uint256 private _MINT_block_id;
    uint256 private _MINT_token_id_from;
    uint256 private _MINT_token_max;
    uint256 private _MINT_chara_max;
    uint256 private _MINT_token_reserved;
    uint256 private _MINT_total_supply;
    uint256[CHARA_TYPE_NUM] private _MINT_arr_chara_supply;

    bool private    _SALE_is_suspended;
    bool private    _SALE_is_suspended_random;
    uint256 private _SALE_start;
    uint256 private _SALE_end;
    uint256 private _SALE_price;
    uint256 private _SALE_price_random;

    //--------------------------------------------------------
    // [modifier] onlyOwnerOrManager
    //--------------------------------------------------------
    modifier onlyOwnerOrManager() {
        require( msg.sender == owner() || msg.sender == manager(), "caller is not the owner neither manager" );
        _;
    }

    //--------------------------------------------------------
    // コンストラクタ
    //--------------------------------------------------------
    constructor() Ownable() {
        transferOwnership( OWNER_ADDRESS );
        _token_contract = IBlockMintable( TOKEN_ADDRESS );

        _manager = msg.sender;

        //-----------------------
        // mainnet
        //-----------------------
        _MINT_block_id = 0;
        _MINT_token_id_from = 1;
        _MINT_token_max = 1800;
        _MINT_chara_max = 150;
        _MINT_token_reserved = 180;
       
        _SALE_start = 1673794800;               // 2023-01-16 00:00:00(JST)
        _SALE_end   = 0;                        // endless
        _SALE_price = 10000000000000000;        // 0.010 ETH
        _SALE_price_random = 8000000000000000;  // 0.008 ETH
    }

    //--------------------------------------------------------
    // [public] manager
    //--------------------------------------------------------
    function manager() public view returns (address) {
        return( _manager );
    }

    //--------------------------------------------------------
    // [external/onlyOwner] setManager
    //--------------------------------------------------------
    function setManager( address target ) external onlyOwner {
        _manager = target;
    }

    //--------------------------------------------------------
    // [external] get
    //--------------------------------------------------------
    function tokenContract() external view returns (address) { return( address(_token_contract) ); }  
    function tokenContractEnabled() external view returns (bool) {return( _token_contract_enabled ); }

    function MINT_blockId() external view returns (uint256) { return( _MINT_block_id ); }
    function MINT_tokenIdFrom() external view returns (uint256) { return( _MINT_token_id_from ); }
    function MINT_tokenMax() external view returns (uint256) { return( _MINT_token_max ); }
    function MINT_charaMax() external view returns (uint256) { return( _MINT_chara_max ); }
    function MINT_tokenReserved() external view returns (uint256) { return( _MINT_token_reserved ); }
    function MINT_totalSupply() external view returns (uint256) { return( _MINT_total_supply ); }
    function MINT_charaSupplyAt( uint256 charaId ) external view returns (uint256) { return( _MINT_arr_chara_supply[charaId] ); }

    function SALE_isSuspended() external view returns (bool) { return( _SALE_is_suspended ); }
    function SALE_isSuspendedRandom() external view returns (bool) { return( _SALE_is_suspended_random ); }
    function SALE_start() external view returns (uint256) { return( _SALE_start ); }
    function SALE_end() external view returns (uint256) { return( _SALE_end ); }
    function SALE_price() external view returns (uint256) { return( _SALE_price ); }
    function SALE_priceRandom() external view returns (uint256) { return( _SALE_price_random ); }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] set
    //--------------------------------------------------------
    function setTokenContract( address target ) external onlyOwnerOrManager {
        _token_contract = IBlockMintable(target);

        // flag off
        _token_contract_enabled = false;
    }

    function MINT_setBlockInfo( uint blockId, uint idFrom, uint256 num, uint256 charaNum, uint256 reserved, uint256 totalSupply, uint256[CHARA_TYPE_NUM] calldata charaSupply ) external onlyOwnerOrManager {
        _MINT_block_id = blockId;
        _MINT_token_id_from = idFrom;
        _MINT_token_max = num;
        _MINT_chara_max = charaNum;
        _MINT_token_reserved = reserved;

        _MINT_total_supply = totalSupply;
        for( uint256 i=0; i<CHARA_TYPE_NUM; i++ ){
            _MINT_arr_chara_supply[i] = charaSupply[i];
        }

        // flag off
        _token_contract_enabled = false;
    }

    function SALE_suspend( bool flag ) external onlyOwnerOrManager { _SALE_is_suspended = flag; }
    function SALE_suspendRandom( bool flag ) external onlyOwnerOrManager { _SALE_is_suspended_random = flag; }
    function SALE_setStartEnd( uint256 start, uint256 end ) external onlyOwnerOrManager { _SALE_start = start; _SALE_end = end; }
    function SALE_setPrice( uint256 price ) external onlyOwnerOrManager { _SALE_price = price; }
    function SALE_setPriceRandom( uint256 price ) external onlyOwnerOrManager { _SALE_price_random = price; }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] updateTokenContractEnabled
    //--------------------------------------------------------
    function updateTokenContractEnabled() external onlyOwnerOrManager {
        // Tokenコントラクトは有効か？
        require( address(_token_contract) != address(0x0), "invalid _token_contract" );

        // Vendorがmint可能か？
        require( address(this) == _token_contract.getBlockMintable( _MINT_block_id ), "Vendor not mintable" );

        // ブロック情報の取得
        uint256 idFrom = _token_contract.getBlockTokenIdFrom( _MINT_block_id );
        uint256 idTo = idFrom + _token_contract.getBlockTokenNum( _MINT_block_id ) - 1;

        // 範囲は有効か？
        require( _MINT_token_id_from >= idFrom, "invalid _MINT_token_id_from" );
        require( (_MINT_token_id_from+_MINT_token_max-1) <= idTo, "invalid _MINT_token_max" );

        // 予約枠は正常か？
        require( _MINT_token_reserved <= _MINT_token_max, "invalid _MINT_token_reserved" );

        // 総数は正常か？
        require( ((_MINT_token_max+CHARA_TYPE_NUM-1)/CHARA_TYPE_NUM) == _MINT_chara_max, "invalid _MINT_chara_max" );

        // 状況は正常か？
        require( _MINT_total_supply <= _MINT_token_max, "invalid _MINT_total_supply" );

        uint256 charaTotal;
        for( uint256 i=0; i<CHARA_TYPE_NUM; i++ ){
            require( _MINT_arr_chara_supply[i] <= _MINT_chara_max, "invalid _MINT_arr_chara_supply" );
            charaTotal += _MINT_arr_chara_supply[i];
        }
        require( _MINT_total_supply == charaTotal, "invalid charaTotal" );

        // ここまできたら有効(MINT可能)
        _token_contract_enabled = true;
    }

    //--------------------------------------------------------
    // [external] getInfo
    //--------------------------------------------------------
    function getInfo() external view returns (uint256[INFO_MAX] memory) {
        uint256[INFO_MAX] memory arrInfo;

        if( _SALE_is_suspended ){ arrInfo[INFO_SALE_SUSPENDED] = 1; }
        if( _SALE_is_suspended_random ){ arrInfo[INFO_SALE_SUSPENDED_RANDOM] = 1; }
        arrInfo[INFO_SALE_START] = _SALE_start;
        arrInfo[INFO_SALE_END] = _SALE_end;
        arrInfo[INFO_SALE_PRICE] = _SALE_price;
        arrInfo[INFO_SALE_PRICE_RANDOM] = _SALE_price_random;
        arrInfo[INFO_MINT_TOKEN_MAX] = _MINT_token_max;
        arrInfo[INFO_MINT_CHARA_MAX] = _MINT_chara_max;
        arrInfo[INFO_MINT_TOTAL_SUPPLY] = _MINT_total_supply;
        for( uint256 i=0; i<CHARA_TYPE_NUM; i++ ){
            arrInfo[INFO_MINT_CHARA_SUPPLY+i] = _MINT_arr_chara_supply[i];
        }

        return( arrInfo );
    }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] reserveTokens
    //--------------------------------------------------------
    function reserveTokens( uint256 num ) external onlyOwnerOrManager {
        require( _token_contract_enabled, "reserveTokens: token contract not enabled" );
        require( (_MINT_total_supply+num) <= _MINT_token_reserved, "reserveTokens: exceeded the reservation range" );

        // mint
        for( uint256 i=0; i<num; i++ ){
            uint256 charaId = (_MINT_token_reserved - _MINT_total_supply) % CHARA_TYPE_NUM;
            _mintToken( owner(), charaId );
        }
    }

    //--------------------------------------------------------
    // [external/payable/nonReentrant] mintCharaAt
    //--------------------------------------------------------
    function mintCharaAt( uint256 charaId ) external payable nonReentrant {
        require( _token_contract_enabled, "mintCharaAt: token contract not enabled" );
        require( _MINT_total_supply >= _MINT_token_reserved, "mintCharaAt: reservation not finished" );

        require( ! _SALE_is_suspended, "mintCharaAt: suspended" );
        require( _SALE_start == 0 || _SALE_start <= (block.timestamp+BLOCK_SEC_MARGIN), "mintCharaAt: not opend" );
        require( _SALE_end == 0 || (_SALE_end+BLOCK_SEC_MARGIN) > block.timestamp, "mintCharaAt: finished" );
        require( msg.value >= _SALE_price, "mintCharaAt: insufficient value" );

        // mint
        _mintToken( msg.sender, charaId );
    }

    //--------------------------------------------------------
    // [external/payable/nonReentrant] mintRandom
    //--------------------------------------------------------
    function mintRandom() external payable nonReentrant {
        require( _token_contract_enabled, "mintRandom: token contract not enabled" );
        require( _MINT_total_supply >= _MINT_token_reserved, "mintRandom: reservation not finished" );

        require( ! _SALE_is_suspended_random, "mintRandom: suspended" );
        require( _SALE_start == 0 || _SALE_start <= (block.timestamp+BLOCK_SEC_MARGIN), "mintRandom: not opend" );
        require( _SALE_end == 0 || (_SALE_end+BLOCK_SEC_MARGIN) > block.timestamp, "mintRandom: finished" );
        require( msg.value >= _SALE_price_random, "mintRandom: insufficient value" );

        // ランダムで抽選する
        uint256 charaId = _randomChara( uint256( keccak256( abi.encodePacked( address(this), msg.sender, _MINT_total_supply ) ) ) );

        // mint
        _mintToken( msg.sender, charaId );
    }

    //--------------------------------------------------------
    // [internal] _mintToken
    //--------------------------------------------------------
    function _mintToken( address to, uint256 charaId ) internal {
        require( charaId < CHARA_TYPE_NUM, "_mintToken: invalid charaId" );
        require( _MINT_total_supply < _MINT_token_max, "_mintToken: reached the supply range" );
        require( _MINT_arr_chara_supply[charaId] < _MINT_chara_max, "_mintToken: reached the chara range" );

        uint256 idOfs = charaId*_MINT_chara_max + _MINT_arr_chara_supply[charaId];
        require( idOfs < _MINT_token_max, "_mintToken: reached the token range" );

        _token_contract.mintByMinter( _MINT_token_id_from+idOfs, to );

        _MINT_total_supply += 1;
        _MINT_arr_chara_supply[charaId] += 1;
    }

    //--------------------------------------------------------
    // [internal] _randomChara
    //--------------------------------------------------------
    function _randomChara( uint256 seed ) internal view returns (uint256) {
        uint256[CHARA_TYPE_NUM] memory weights;
        for( uint256 i=0; i<CHARA_TYPE_NUM; i++ ){
            weights[i] = _MINT_chara_max - _MINT_arr_chara_supply[i];
        }

        // 微調整（CHARA_TYPE_NUMの倍数にならない供給数の場合は末尾から１つずつ間引く）
        uint256 adj = _MINT_token_max % CHARA_TYPE_NUM;
        if( adj > 0 ){
            for( uint256 i=adj; i<CHARA_TYPE_NUM; i++ ){
                weights[i]--;
            }
        }

        // 重さの累積
        uint256 totalWeight;
        for( uint256 i=0; i<CHARA_TYPE_NUM; i++ ){
            totalWeight += weights[i];
        }
        require( totalWeight > 0, "_randomChara: no candidate" );

        uint256 temp = seed % totalWeight;
        for( uint256 i=0; i<CHARA_TYPE_NUM; i++ ){
            if( temp < weights[i] ){ return( i ); }
            temp -= weights[i];
        }

        require( false, "_randomChara: fatal error" );
        return( 0 );
    }

    //--------------------------------------------------------
    // [external] checkBalance
    //--------------------------------------------------------
    function checkBalance() external view returns (uint256) {
        return( address(this).balance );
    }

    //--------------------------------------------------------
    // [external/onlyOwnerOrManager] withdraw
    //--------------------------------------------------------
    function withdraw( uint256 amount ) external onlyOwnerOrManager {
        require( amount <= address(this).balance, "insufficient balance" );

        address payable target = payable( owner() );
        target.transfer( amount );
    }

}