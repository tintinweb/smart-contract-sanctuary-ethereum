/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: PropAuction
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


contract PropAuction is Ownable,ReentrancyGuard {
    //判断合约是721还是1155
    bytes4 private constant _INTERFACE_ID_ERC1155=type(IERC1155).interfaceId;
    bytes4 private constant _INTERFACE_ID_ERC721=type(IERC721).interfaceId;
    /**************属性****************/
    /*当前订单号*/
    uint256 public orderId;
    /**拍卖单详情*/
    struct order{
        address     account;            //卖家地址
        address     gameContract;       //游戏合约
        uint256     tokenId;            //装备tokenId
        uint256     number;             //挂卖数量
        address     to;                 //中标地址
        uint256     transactionPrice;   //成交价
        uint64      state;              //状态      1 拍卖中  2 拍完成功  3 取消拍卖  4 流拍
    }
    //订单集合
    mapping(uint256=>order) public orders;
    /**************事件****************/
    /**发布拍卖*/
    event _releaseAuction(uint256 _orderId,address from,address gameContract_,uint256 tokenId_,uint256 number_);
    /**取消拍卖*/
    event _cancelTheAuction(uint256 _orderId); 
    /**拍卖成功*/
    event _successfulAuction(uint256 _orderId);
    /**
     * 构造函数
     * parameter   uint256     orderId_       初始化订单号
     * parameter   add     orderId_       初始化订单号
    */
    constructor(uint256 orderId_)
        {
            //初始化订单号
            orderId = orderId_;
            //给自己管理员权限
            transferOwnership(msg.sender);
        }
    
    /** 发布拍卖
     *  Role        ALL
     *  parameter   address     gameContract_   道具合约地址
     *  parameter   address     glodContract_   代币合约地址
     *  parameter   uint256     tokenId_        道具tokenid
     *  parameter   uint256     number_         挂卖数量
     *  parameter   uint256     startTime_      拍卖开始时间
     *  returns     bool                        成功或失败
    */
    function accountAddTheOrder(
        address gameContract_,
        uint256 tokenId_,
        uint256 number_
        ) 
        nonReentrant
        public 
        returns(bool)
        {
            return toAddTheOrder(gameContract_,tokenId_,number_);
        }
    /** 发布
     *  Role        私有的                   
    */
    function toAddTheOrder(
        address gameContract_,
        uint256 tokenId_,
        uint256 number_
        )
        internal
        returns(bool)
        {
            orderId = orderId + 1;  //订单号累加1
            orders[orderId] = order(msg.sender,gameContract_,tokenId_,number_,address(0x00),0,1);
            _transferToken(gameContract_,msg.sender,address(this),tokenId_,number_);//将装备从卖家处转移到本合约地址
            emit _releaseAuction(orderId,msg.sender,gameContract_,tokenId_,number_);
            return true;
        }

    /** 查看订单详情
     *  Role        ALL
     *  parameter   uint256     orderId_           订单号
     *  returns     address     account_           卖家地址
     *  returns     address     gameContract_      道具合约地址
     *  returns     address     glodContract_      币种合约地址
     *  returns     uint256     tokenId_           道具id
     *  returns     uint256     number_            道具数量
     *  returns     uint256     startingpPrice_    起拍价
     *  returns     uint256     startTime_         开始时间
    */   
    function theOrderDetailsIm(uint256 orderId_)
        view
        public
        returns(
            address account_,
            address gameContract_,
            uint256 tokenId_,
            uint256 number_
            )
        {
            return (orders[orderId_].account,orders[orderId_].gameContract,orders[orderId_].tokenId,orders[orderId_].number);
        }    
    /** 查看订单状态
     *  Role        ALL
     *  parameter   uint256     orderId_            订单号
     *  returns     address     to_                 中标地址
     *  returns     uint256     transactionPrice_   中标价
     *  returns     uint64      state_              状态
    */   
    function theOrderState(uint256 orderId_)
        view
        public
        returns(
            address to_,
            uint256 transactionPrice_,
            uint64 state_
            )
        {
            return (orders[orderId_].to,orders[orderId_].transactionPrice,orders[orderId_].state);
        }

    /** 取消拍卖
     *  Role        共有的
     *  parameter   address     orderId_    订单号
     *  returns     bool                        
    */
    function toCancel(uint256 orderId_)
        nonReentrant
        public
        onlyOwner()
        returns(bool)
        {
            order storage myOrder= orders[orderId_];
            require (myOrder.state == 1,'Abnormal order status');                  //判断订单状态是不是拍卖中
            myOrder.state = 3;                                            //修改订单状态为取消
            _transferToken(myOrder.gameContract,address(this),msg.sender,myOrder.tokenId,myOrder.number);//将装备退给卖家
            emit _cancelTheAuction(orderId_);
            return true;
        }  
 

    /** 拍卖成功
     *  Role        私有的
     *  parameter   uint256     orderId_            订单号
     *  parameter   address     to_                 中标人
     *  returns     bool                        
    */    
    function successfulAuction(uint256 orderId_,address to_)
        nonReentrant
        public
        payable
        onlyOwner()
        returns(bool)
        {
            order storage myOrder= orders[orderId_];
            require (myOrder.state == 1,'Abnormal order status');                          //判断订单状态是否是拍卖中
            myOrder.state = 2;
            myOrder.to = to_;
            _transferToken(myOrder.gameContract,address(this),to_,myOrder.tokenId,myOrder.number);//将装备给买家
            emit _successfulAuction(orderId_);      //发布购买事件 
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