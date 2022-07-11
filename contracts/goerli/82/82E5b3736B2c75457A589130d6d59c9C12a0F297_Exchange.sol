/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: Exchange
pragma solidity ^0.8.0;


interface GlodContract{
    function transfer(address sender,uint256 amount) external returns (bool);
    function transferFrom(address sender,address to,uint256 amount) external returns (bool);
    
}
interface NftContract{
    function totalSupply() external view  returns (uint256);
    function toTransfer(address from_,address to_,uint256 tokenId_) external returns (bool);
    function ownerOf(uint256 tokenid_) external view returns (address);
}


contract Exchange{

    //管理员
    address public _owner;
    modifier Owner {   //管理员
        require(_owner == msg.sender);
        _;
    }
   
    /*服务费千分比*/
    uint256 public serviceCharge;
    /**服务费地址*/
    address public chargingAddress;

    /*当前订单号*/
    uint256 public orderId;
    //订单集合
    mapping(uint256=>order) public orders; 
    /**订单详情*/
    struct order{
        address     account;            //卖家地址
        address     nftContract;        //游戏合约
        address     glodContract;       //币种合约
        uint256     price;              //出售价格(注意小数位)
        uint256     tokenId;            //装备tokenId
        address     to;                 //买家地址
        uint64      state;              //交易状态  1挂单中  2交易完成  3交易取消
    }
    




    /**************事件****************/
    /**发布订单*/
    event _addTheOrder(uint256 _orderId);
    /**取消订单*/
    event _cancellationOfOrder(uint256 _orderId); 
    /**购买订单*/
    event _buyOrder(uint256 _orderId);
    /**修改订单*/
    event _changeOrder(uint256 _orderId);


    
    
    /**
     * 构造函数
     * parameter   uint256     orderId_                             初始化订单号
     * parameter   uint256     serviceCharge_                       初始化手续费千分比
     * parameter   address     waiter_                              初始化手续费地址
    */
    constructor(uint256 orderId_,uint256 serviceCharge_,address chargingAddress_)
        {
            require (serviceCharge_ > 0 && serviceCharge_ < 1000,"parameter error");
            //初始化订单号
            orderId = orderId_;
            //初始化手续费千分比
            serviceCharge = serviceCharge_;
            //初始化收取手续费地址
            chargingAddress = address(chargingAddress_);
            //给自己管理员权限
            _owner = msg.sender; //默认自己为管理员
        }

    /** 修改服务费千分比*/
    function modifyingServiceCharges(uint256 serviceCharge_)
        public 
        Owner
        returns(bool)
        {
            require (serviceCharge_ > 0 && serviceCharge_ < 1000,"parameter error");
            serviceCharge = serviceCharge_;
            return true;
        }
    
    /** 修改服务费收取地址*/
    function modifyTheServer(address chargingAddress_)
        public
        Owner
        returns(bool)
        {
            chargingAddress = chargingAddress_;
            return true;
        }

    /** 发布订单*/
    function toAddTheOrder(address nftContract_,address glodContract_,uint256 price_,uint256 tokenId_)
        public
        returns(bool)
        {
            orderId = orderId + 1;
            orders[orderId] = order(msg.sender,nftContract_,glodContract_,price_,tokenId_,address(0x00),1);
            _transferToken(nftContract_,msg.sender,address(this),tokenId_);
            emit _addTheOrder(orderId);
            return true;
        }
        
    /** 查看订单详情*/   
    function theOrderDetailsImmutable(uint256 orderId_)
        view
        public
        returns(address account_,address gameContract_,address glodContract_,uint256 tokenId_,address to_,uint256 price_,uint256 state_)
        {
            return (orders[orderId_].account,
                    orders[orderId_].nftContract,
                    orders[orderId_].glodContract,
                    orders[orderId_].tokenId,
                    orders[orderId_].to,
                    orders[orderId_].price,
                    orders[orderId_].state
                    );
        } 
    /** 取消订单*/
    function toCancel(uint256 orderId_)
        public
        returns(bool)
        {
            order storage myOrder= orders[orderId_];
            require (msg.sender == myOrder.account,"Do not have permission");
            require (myOrder.state == 1,"Abnormal order status");
            myOrder.state = 3;
            _transferToken(myOrder.nftContract,address(this),msg.sender,myOrder.tokenId);
            emit _cancellationOfOrder(orderId_);
            return true;
        }  
    
    /** 购买订单*/    
    function buyOrder(uint256 orderId_)
        public
        payable
        returns(bool)
        {
            order storage myOrder= orders[orderId_];
            require (myOrder.state == 1,"Abnormal order status");
            myOrder.state = 2;
            myOrder.to = msg.sender;
            GlodContract coinContract = GlodContract(myOrder.glodContract);  
            //这里需要判断是否收取手续费
            uint256 transactionServiceCharge = myOrder.price * serviceCharge / 2000; 
            uint256 transactionFee = myOrder.price - transactionServiceCharge;        
            coinContract.transferFrom(msg.sender,myOrder.account,transactionFee);
            coinContract.transferFrom(msg.sender,chargingAddress,transactionServiceCharge);
            _transferToken(myOrder.nftContract,address(this),msg.sender,myOrder.tokenId);
            emit _buyOrder(orderId_);
            return true;
        }  

    /** 721转移token*/    
    function _transferToken(address _contractAddress,address _from,address _to,uint256 _tokenid)
        internal 
        returns(bool) 
        {
            NftContract(_contractAddress).toTransfer(_from,_to,_tokenid);
            return true;
        }  
    

    function onERC1155Received(address,address,uint256,uint256,bytes calldata) external pure returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
    
}