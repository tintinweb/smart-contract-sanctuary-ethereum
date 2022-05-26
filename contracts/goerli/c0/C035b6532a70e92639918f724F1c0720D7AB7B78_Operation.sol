/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: Operation
pragma solidity ^0.8.0;

interface GlodContract{
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}
interface NftContract{
    function toMint(address to_,uint256 type_) external returns (bool);
    function toTransfer(address from_,address to_,uint256 tokenId_) external returns (bool);
    function toBurn(uint256 tokenId_) external returns (bool);
    function tokenIdType(uint256 tokenId_) external returns (uint256);
    function ownerOf(uint256 tokenId) external view  returns (address);
    function balanceOf(address owner) external view  returns (uint256);
    
    
}
interface Team{
    function team(address from_) external returns (address);
    function bindingWhite(address from_ , address to_) external returns (bool);
}

//中介合约 Operation.sol
contract Operation{
    address public TeslaContract = address(0x00);
    address public BlindBoxContract = address(0x00);
    address public ShareholderContract = address(0x00);
    address public TeamContract = address(0x00);
    address public CollectionAddress = address(0x00);
    /**
     * 管理员
    */
    address public _owner;
    modifier Owner {   //管理员
        require(_owner == msg.sender);
        _;
    }
    /**
     * USDT地址
    */
    address public UsdtAddress = 0x12e7af2439bEB582C3F6a35f97071Ec7a4CfA3d5;
    /**
     * 设定盲盒价格
    */
    uint256 public PriceFeng = 1;
    uint256 public PriceJing = 100;
    

    /**
     * 设定股东卡价格
    */
    uint256 public PriceCard = 1000;
    uint256 public PriceCardVip = 5000;

    /**
     * 推荐购买股东卡人数;
    */
    mapping(address=>mapping(address=>bool)) public RePurchase;
    mapping(address=>uint256) public RePurchaseQuantity;


    /**************事件****************/
    /**买盲盒*/
    // event BlindBoxBuy(address _orderId);



    /**
     * 构造函数
     * parameter   address     TeslaContract_           特斯拉合约地址
     * parameter   address     BlindBoxContract_        盲盒合约地址
     * parameter   address     ShareholderContract_     股东卡合约地址
     * parameter   address     TeamContract_            上下级合约
     * parameter   address     CollectionAddress_       收款地址
    */
    constructor(address TeslaContract_ , address BlindBoxContract_ , address ShareholderContract_, address TeamContract_ , address CollectionAddress_){
        //特斯拉合约
        TeslaContract = TeslaContract_;
        //盲盒合约
        BlindBoxContract = BlindBoxContract_;
        //股东卡合约
        ShareholderContract = ShareholderContract_;
        //上下级合约
        TeamContract = TeamContract_;
        //收款地址
        CollectionAddress = CollectionAddress_;
        _owner = msg.sender; //默认自己为管理员
    }
    /**
    *   修改管理员  权限    Owner
    *   owner_  新管理员地址
    */
    function setOwner(address owner_) public Owner returns (bool){
        _owner = owner_;
        return true;
    }
    /**
    *   修改收款地址  权限    Owner
    *   CollectionAddress_  新的收款地址
    */
    function setCollectionAddress(address CollectionAddress_) public Owner returns (bool){
        CollectionAddress = CollectionAddress_;
        return true;
    }
    /**
    *   修改盲盒价格       权限    Owner
    *   newPrice_         新的价格
    *   type_             盲盒种类  1 锋盒  2 镜盒
    */
    function setPriceBlindBox(uint256 newPrice_ , uint256 type_) public Owner returns (bool){
        if(type_ == 1){
            PriceFeng = newPrice_;
        }else if(type_ == 2){
            PriceJing = newPrice_;
        }else{
            require(false, "Parameter error");
        }
        return true;
    }

    /**
    *   修改股东卡价格       权限    Owner
    *   newPrice_         新的价格
    *   type_             卡种类  1 普通  2 创世
    */
    function setPriceCard(uint256 newPrice_ , uint256 type_) public Owner returns (bool){
        if(type_ == 1){
            PriceCard = newPrice_;
        }else if(type_ == 2){
            PriceCardVip = newPrice_;
        }else{
            require(false, "Parameter error");
        }
        return true;
    }
    /**
    *   买盲盒       ALL
    *   type_             盲盒种类  1 锋盒  2 镜盒
    */
    function buyBlindBox(uint256 type_,address superior_) public returns(bool){
        Team Teams = Team(TeamContract);
        if(Teams.team(msg.sender) == address(0x00)){
            Teams.bindingWhite(msg.sender,superior_);
        }
        GlodContract Glod =  GlodContract(UsdtAddress);
        NftContract BlindBox =  NftContract(BlindBoxContract);
        if(type_ == 1){
            Glod.transferFrom(msg.sender,address(CollectionAddress),PriceFeng * 10**Glod.decimals());
        }else if(type_ == 2){
            Glod.transferFrom(msg.sender,address(CollectionAddress),PriceJing * 10**Glod.decimals());
        }else{
            require(false, "Parameter error");
        }
        BlindBox.toMint(msg.sender,type_);
        return true;
    }
    /**
    *   开盲盒       ALL
    *   tokenId_            盲盒tokenid
    */
    function openBlindBox(uint256 tokenId_) public returns(bool){
        NftContract BlindBox =  NftContract(BlindBoxContract);
        NftContract Tesla = NftContract(TeslaContract); 
        require(BlindBox.ownerOf(tokenId_) == msg.sender , "Parameter error");
        if(BlindBox.tokenIdType(tokenId_) == 1){ 
            uint256 PoweRand = _PoweRand(0,10000);
            if(PoweRand <= 2){
                require(Tesla.toMint(msg.sender,6), "Casting failure");
            }
            if(PoweRand > 2 && PoweRand <= 5){
                require(Tesla.toMint(msg.sender,5), "Casting failure");
            }
            if(PoweRand > 5 && PoweRand <= 10){
                require(Tesla.toMint(msg.sender,4), "Casting failure");
            }
            if(PoweRand > 10 && PoweRand <= 100){
                require(Tesla.toMint(msg.sender,3), "Casting failure");
            }
            if(PoweRand > 100 && PoweRand <= 500){
                require(Tesla.toMint(msg.sender,2), "Casting failure");
            }
            if(PoweRand > 500){
                require(Tesla.toMint(msg.sender,1), "Casting failure");
            }

        }else if(BlindBox.tokenIdType(tokenId_) == 2){
            uint256 PoweRand = _PoweRand(0,100);
            if(PoweRand <= 2){
                require(Tesla.toMint(msg.sender,6), "Casting failure");
            }
            if(PoweRand > 2 && PoweRand <= 7){
                require(Tesla.toMint(msg.sender,5), "Casting failure");
            }
            if(PoweRand > 7 && PoweRand <= 15){
                require(Tesla.toMint(msg.sender,4), "Casting failure");
            }
            if(PoweRand > 15 && PoweRand <= 25){
                require(Tesla.toMint(msg.sender,3), "Casting failure");
            }
            if(PoweRand > 25){
                require(Tesla.toMint(msg.sender,2), "Casting failure");
            }
        }else{
            require(false, "Parameter error");
        }
        require(BlindBox.toBurn(tokenId_), "Destroy failed");
        return true;
    }

    /**
    *   买股东卡       ALL
    *   type_         股东卡种类  1 普通  2 创世
    */
    function buyCard(uint256 type_,address superior_) public returns(bool){
        GlodContract Glod =  GlodContract(UsdtAddress);
        NftContract Shareholder =  NftContract(ShareholderContract);
        Team Teams = Team(TeamContract);
        if(Teams.team(msg.sender) == address(0x00)){
            Teams.bindingWhite(msg.sender,superior_);
        }
        if(type_ == 1){
            Glod.transferFrom(msg.sender,address(CollectionAddress),PriceCard * 10**Glod.decimals());
            if(!RePurchase[superior_][msg.sender]){
                if(Shareholder.balanceOf(superior_) > 0){
                    RePurchaseQuantity[superior_] += 1;
                }
                RePurchase[superior_][msg.sender] = true;
            }
            if(RePurchaseQuantity[superior_] == 5){
                Shareholder.toMint(superior_,1);
            }
        }else if(type_ == 2){
            Glod.transferFrom(msg.sender,address(CollectionAddress),PriceCardVip * 10**Glod.decimals());
        }else{
            require(false, "Parameter error");
        }
        NftContract BlindBox =  NftContract(BlindBoxContract);
        for(uint i = 0; i < 100 ; i++){
            BlindBox.toMint(msg.sender,1);
        }
        Shareholder.toMint(msg.sender,type_);
        
        return true;
    }



     
    /**
    * 生成随机数
    */
    function _PoweRand(uint256 min_,uint256 poor_) internal view returns(uint256 PoweRand){
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        uint256 rand = random % poor_;
        return (min_ + rand);
    }
    function onERC1155Received(address,address,uint256,uint256,bytes calldata) external pure returns(bytes4){
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }
}