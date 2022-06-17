/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: Operation
pragma solidity ^0.8.0;
interface NftContract{
    function toMint(address to_) external returns (bool);
    function toMints(address to_,uint256 amount_) external returns (bool);
    function toTransfer(address from_,address to_,uint256 tokenId_) external returns (bool);
    function toBurn(uint256 tokenId_) external returns (bool);
    function tokenIdType(uint256 tokenId_) external returns (uint256);
    function ownerOf(uint256 tokenId) external view  returns (address);
    function balanceOf(address owner) external view  returns (uint256);
    function horsePower(uint256 tokenId) external view  returns (uint256);
    
}


//中介合约 Operation.sol
contract Match{
    /**
     * 管理员
    */
    address public _owner;
    modifier Owner {   //管理员
        require(_owner == msg.sender);
        _;
    }


    //记录报名信息
    mapping(uint256=>order) public UserSignUp;
    uint256 public orderId = 1000000;
    /**报名记录表*/
    struct order{
        address     CarContract_;       //汽车合约
        uint256     tokenId_;           //tokenid
        address     from_;              //报名人
        uint256     time_;              //报名时间
        bool        state_;             //报名状态 
    }

    /**
     * 报名事件;
     * CarContract_     汽车合约地址;
     * tokenId_         tokenid;
     * from_            报名人
     * horsePower_      汽车马力;
     * orderid_         报名编号
    */
    event SignUpEvent(address CarContract_,uint256 tokenId_,address from_,uint256 horsePower_,uint256 orderid_);

    /**
     * 取消报名事件;
     * CarContract_     汽车合约地址;
    */
    event CancelSignUpEvent(uint256 orderid_);

    /**
     * 质押车辆用来激活才赛下赛季;
     * CarContract_     汽车合约地址;
    */
    event DestructionEvent(address from_,address TeslaContract_);



    /**
     * 构造函数
    */
    constructor(){
        _owner = msg.sender; //默认自己为管理员
    }
    

    /**
     * 报名
    */
    function SignUp(address CarContract_,uint256 tokenId_) public returns(bool){
        NftContract Tesla = NftContract(CarContract_);
        require(Tesla.ownerOf(tokenId_) == msg.sender, "Not your car");
        Tesla.toTransfer(msg.sender,address(this),tokenId_);
        UserSignUp[orderId] = order(CarContract_,tokenId_,msg.sender,block.timestamp,true);
        emit SignUpEvent(CarContract_,tokenId_,msg.sender,Tesla.horsePower(tokenId_),orderId);
        orderId +=1;
        return true;
    }

    /**
     * 取消报名
    */
    function CancelSignUp(uint256 orderId_) public returns(bool){
        require(UserSignUp[orderId_].from_ == msg.sender, "Not your order");
        require(UserSignUp[orderId_].state_, "Abnormal order status");
        UserSignUp[orderId_].state_ = false;
        NftContract Tesla = NftContract(UserSignUp[orderId_].CarContract_);
        Tesla.toTransfer(address(this),msg.sender,UserSignUp[orderId_].tokenId_);
        emit CancelSignUpEvent(orderId_);
        return true;
    }


    //销毁赛车NFT
    function Destruction(address CarContract_,uint256 tokenId_) public returns(bool){
        NftContract Tesla = NftContract(CarContract_);
        require(Tesla.ownerOf(tokenId_) == msg.sender, "Not your car");
        Tesla.toTransfer(msg.sender,address(CarContract_),tokenId_);
        emit DestructionEvent(msg.sender,CarContract_);
        return true;
    }


    function onERC1155Received(address,address,uint256,uint256,bytes calldata) external pure returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}