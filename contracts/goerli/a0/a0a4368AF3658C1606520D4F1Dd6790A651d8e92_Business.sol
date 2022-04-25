/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

// SPDX-License-Identifier: Business
pragma solidity ^0.8.0;
// IERC20 合约接口
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
} 
// IERC165 合约接口
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// IERC721 合约接口
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
// IERC1155 合约接口
interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
// ERC165Checker  判断合约是721合约还是1155合约时需要
library ERC165Checker {
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;
    function supportsERC165(address account) internal view returns (bool) {
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        if (supportsERC165(account)) {
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }
        return interfaceIdsSupported;
    }
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        if (!supportsERC165(account)) {
            return false;
        }
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }
        return true;
    }
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}
// Context
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// Ownable  权限
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    // 销毁持有者
    // function renounceOwnership() public virtual onlyOwner {
    //     _transferOwnership(address(0));
    // }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// ReentrancyGuard 防重入
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}


//正式合约
contract Business is Ownable,ReentrancyGuard {
    //判断合约是721还是1155
    bytes4 private constant _INTERFACE_ID_ERC1155=type(IERC1155).interfaceId;
    bytes4 private constant _INTERFACE_ID_ERC721=type(IERC721).interfaceId;
    /**************属性****************/
    /*当前订单号*/
    uint256 public orderId;
    /*服务费千分比*/
    uint256 public serviceCharge;
    /**服务费地址*/
    address public chargingAddress;
    /**订单详情*/
    struct order{
        address     account;            //卖家地址
        address     gameContract;       //NFT合约
        address     glodContract;       //币种合约
        uint256     price;              //出售价格(注意小数位)
        uint256     tokenId;            //装备tokenId
        uint256     number;             //挂卖数量
        uint64      state;              //交易状态  1挂单中  2交易完成  3交易取消
    }
    //订单集合
    mapping(uint256=>order) orders; 
    /**************事件****************/
    /**发布订单*/
    event _addTheOrder(uint256 _orderId,address _from,address _gameContract,address _glodContract,uint256 _price,uint256 _tokenId,uint256 _number);
    /**取消订单*/
    event _cancellationOfOrder(uint256 _orderId); 
    /**购买订单*/
    event _buyOrder(uint256 _orderId);
    /**
     * 构造函数
     * parameter   uint256     orderId_                             初始化订单号
     * parameter   uint256     serviceCharge_                       初始化手续费千分比
     * parameter   address     waiter_                              初始化手续费地址
    */
    constructor(uint256 orderId_,uint256 serviceCharge_,address chargingAddress_)
        {
            require (serviceCharge_ > 0 && serviceCharge_ < 1000,'parameter error');
            //初始化订单号
            orderId = orderId_;
            //初始化手续费千分比
            serviceCharge = serviceCharge_;
            //初始化收取手续费地址
            chargingAddress = address(chargingAddress_);
            //给自己管理员权限
            transferOwnership(msg.sender);
        }
    /** 修改服务费千分比
     *  parameter   uint256     serviceCharge_    新服务费千分比(0--1000)
     *  returns     bool                          成功或失败
    */
    function modifyingServiceCharges(uint256 serviceCharge_)
        public 
        onlyOwner()
        returns(bool)
        {
            require (serviceCharge_ > 0 && serviceCharge_ < 1000,'parameter error');
            serviceCharge = serviceCharge_;
            return true;
        }
    /** 修改服务费收取地址
     *  parameter   address     chargingAddress_    服务费收取地址新
     *  returns     bool                            成功或失败
    */
    function modifyTheServer(address chargingAddress_)
        public
        onlyOwner()
        returns(bool)
        {
            chargingAddress = chargingAddress_;
            return true;
        }
    /** 发布订单
     *  Role        ALL
     *  parameter   address     gameContract_   道具合约地址
     *  parameter   address     glodContract_   代币合约地址
     *  parameter   uint256     price_          出售价格
     *  parameter   uint256     tokenId_        道具tokenid
     *  parameter   uint256     number_         挂卖数量
     *  returns     bool                        成功或失败
    */
    function accountAddTheOrder(address gameContract_,address glodContract_,uint256 price_,uint256 tokenId_,uint256 number_) 
        nonReentrant
        public 
        returns(bool)
        {
            orderId = orderId + 1;  //订单号累加1
            orders[orderId] = order(msg.sender,gameContract_,glodContract_,price_,tokenId_,number_,1);
            _transferToken(gameContract_,msg.sender,address(this),tokenId_,number_);//将装备从卖家处转移到本合约地址
            emit _addTheOrder(orderId,msg.sender,gameContract_,glodContract_,price_,tokenId_,number_);
            return true;
        }
    /** 查看订单道具详情
     *  Role        ALL
     *  parameter   uint256     orderId_           订单号
     *  returns     address     account_           卖家地址
     *  returns     address     gameContract_      道具合约地址
     *  returns     uint256     tokenId_           道具id
     *  returns     uint256     number_            道具数量
    */   
    function theOrderDetails(uint256 orderId_)
        view
        public
        returns(address account_,address gameContract_,uint256 tokenId_,uint256 number_)
        {
            return (orders[orderId_].account,orders[orderId_].gameContract,orders[orderId_].tokenId,orders[orderId_].number);
        }
    /** 查看订单交易状态
     *  Role        ALL
     *  parameter   uint256     orderId_           订单号
     *  returns     address     glodContract_      币种合约地址
     *  returns     uint256     price_             价格
     *  returns     uint256     state_             状态
    */   
    function theTransactionDetails(uint256 orderId_)
        view
        public
        returns(address glodContract_,uint256 price_,uint256 state_)
        {
            return (orders[orderId_].glodContract,orders[orderId_].price,orders[orderId_].state);
        }
    /** 取消订单
     *  Role        ALL
     *  parameter   uint256     orderId_        订单号
     *  returns     bool                        操作成功或失败
    */   
    function cancellationOfOrder(uint256 orderId_)
        nonReentrant
        public
        returns(bool)
        {
            order storage myOrder= orders[orderId_];
            require (msg.sender == myOrder.account,'Do not have permission');      //判断是不是订单发起人
            require (myOrder.state == 1,'Abnormal order status');                  //判断订单状态是不是未交易
            myOrder.state = 3;                                            //修改订单状态为取消
            _transferToken(myOrder.gameContract,address(this),msg.sender,myOrder.tokenId,myOrder.number);//将装备退给卖家
            emit _cancellationOfOrder(orderId_);
            return true;
        } 
    /** 购买订单
     *  Role        ALL
     *  parameter   uint256     orderId_        订单号
     *  returns     bool                        操作成功或失败
    */
    function buyOrder(uint256 orderId_)
        nonReentrant
        public
        payable
        returns(bool)
        {
            order storage myOrder= orders[orderId_];
            require (myOrder.state == 1,'Abnormal order status');                          //判断订单状态是否是未交易
            myOrder.state = 2;
            if(myOrder.glodContract != address(0x00)){
                //代币交易
                //初始化币种合约地址
                IERC20 coinContract = IERC20(myOrder.glodContract);                          //买家付款
                coinContract.transferFrom(msg.sender,myOrder.account,myOrder.price);
                uint256 transactionServiceCharge = myOrder.price * serviceCharge / 1000;       //计算手续费
                uint256 transactionFee = myOrder.price - transactionServiceCharge;             //计算卖家应收的金额
                coinContract.transferFrom(msg.sender,myOrder.account,transactionFee);
                coinContract.transferFrom(msg.sender,chargingAddress,transactionServiceCharge);
            }else{
                //链币交易
                require (msg.value >= myOrder.price,'Insufficient transaction amount');                //买家付款
                uint256 transactionServiceCharge = myOrder.price * serviceCharge / 1000;      //计算手续费
                uint256 transactionFee = myOrder.price - transactionServiceCharge;             //计算卖家应收的金额
                payable(myOrder.account).transfer(transactionFee);
                payable(chargingAddress).transfer(transactionServiceCharge); 
            }
            _transferToken(myOrder.gameContract,address(this),msg.sender,myOrder.tokenId,myOrder.number);//将装备给买家
            emit _buyOrder(orderId_);      //发布购买事件 
            return true;
        }

    /** 转移token
     *  Role        私有的
     *  parameter   address     _contractAddress    合约地址
     *  parameter   address     _from               转出地址
     *  parameter   address     _to                 转入地址
     *  parameter   uint256     _tokenid                 转入地址
     *  parameter   uint256     _number             数量
     *  returns     bool                        
    */    
    function _transferToken(address _contractAddress,address _from,address _to,uint256 _tokenid,uint256 _number)
        internal 
        returns(bool) 
        {
            uint256 contractType = _eRCSupportsInterfaceCheck(_contractAddress);
            if(contractType == 1){
                //721合约
                IERC721(_contractAddress).transferFrom(_from,_to,_tokenid); //将装备从卖家处转移到本合约地址
            }else if(contractType == 2){
                //1155合约
                IERC1155(_contractAddress).safeTransferFrom(_from,_to,_tokenid,_number,''); //将装备从卖家处转移到本合约地址
            }else{
                //合约不支持
                revert('Contract not supported');
            }
            return true;
        } 

    /** 判断合约是721合约还是1155合约
     *  Role        私有的
     *  parameter   address     _nftContract    合约地址
     *  returns     uint256                     1.721   2.1155  0不知道是啥
    */
    function _eRCSupportsInterfaceCheck(address _nftContract) 
        internal 
        view 
        returns(uint256) 
        {
            bool[] memory supportsRes;
            bytes4[] memory interfaceIds = new bytes4[](2);
            interfaceIds[0] = _INTERFACE_ID_ERC721;
            interfaceIds[1] = _INTERFACE_ID_ERC1155; 
            supportsRes = ERC165Checker.getSupportedInterfaces(_nftContract,interfaceIds);
            if (supportsRes[0]) {
                return 1;//721
            }else if (supportsRes[1]) {
                return 2;//1155
            }else{
                return 0;
            }
        }
    function onERC1155Received(address,address,uint256,uint256,bytes calldata) external pure returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

}