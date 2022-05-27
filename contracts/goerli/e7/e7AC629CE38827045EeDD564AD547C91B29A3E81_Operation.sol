/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: Operation
pragma solidity ^0.8.0;

interface GlodContract{
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}
interface NftContract{
    function toMint(address to_) external returns (bool);
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
    address public TeslaModel3Contract = address(0xbeC159dc0abdaE5365eF33bdd4A097a9DCfa246D) ;      //Model3合约地址
    address public TeslaModelyContract = address(0x67643Af56471E2303C8646B86b422Cd64A202D2c)  ;      //Modely合约地址
    address public TeslaModelxContract = address(0xE848E6Bc36ED5851db351FF364C20f1C44B6502D)  ;      //Modelx合约地址
    address public TeslaModelsContract = address(0xD587161B25B5575b64E26B0266B2a4CF1246Dd8F)  ;      //Models合约地址
    address public TeslaRoadsterContract = address(0x602e27E3Fce93eD13990EaB740608FDC2B2BFf15)  ;    //Roadster合约地址
    address public TeslaSpaceXContract = address(0xEA28889aD123354730bd97614127cb912234A3D8)  ;      //SpaceX合约地址
    address public FrontBoxContract = address(0x98d3194289aEBB556BAc9d5929cac565Cc83F2d6)  ;         //锋盒合约地址
    address public MirrorBoxContract = address(0x89D2297825AfD219c806dC84E3e04B24aC427797)  ;        //镜盒合约地址
    address public OriginationContract = address(0x885f312A9AB005F4CE3aC27Df10eb07D3096426C) ;       //初始股东卡
    address public OrdinaryContract = address(0x35f46b23f6a39282899A8364826167A10b12b40E) ;          //股东卡
    address public TeamContract = address(0xf3973802c4B4465Ed7e2EDB0Cd119CD9593A1F14) ;             //上下级关系
    address public CollectionAddress = address(0x00) ;         //收款地址

    /**
     * USDT地址 0x12e7af2439bEB582C3F6a35f97071Ec7a4CfA3d5
    */
    address public UsdtAddress = address(0x12e7af2439bEB582C3F6a35f97071Ec7a4CfA3d5);
    /**
     * 管理员
    */
    address public _owner;
    modifier Owner {   //管理员
        require(_owner == msg.sender);
        _;
    }
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


    /**
     * 构造函数
     * parameter   address     CollectionAddress_       收款地址
    */
    constructor(address CollectionAddress_){
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
    *   type_       盲盒种类  1 锋盒  2 镜盒
    *   superior_   推荐人地址
    *   quantity_   购买数量
    */
    function buyBlindBox(uint256 type_,address superior_,uint256 quantity_) public returns(bool){
        require(quantity_ <= 10, "Parameter error");
        Team Teams = Team(TeamContract);
        if(Teams.team(msg.sender) == address(0x00)){
            Teams.bindingWhite(msg.sender,superior_);
        }
        GlodContract Glod =  GlodContract(UsdtAddress);
        if(type_ == 1){
            Glod.transferFrom(msg.sender,address(CollectionAddress),PriceFeng * quantity_ * 10**Glod.decimals());
            NftContract BlindBox =  NftContract(FrontBoxContract);
            for(uint i = 0; i < quantity_ ; i++){
                BlindBox.toMint(msg.sender);
            }
        }else if(type_ == 2){
            Glod.transferFrom(msg.sender,address(CollectionAddress),PriceJing * quantity_ * 10**Glod.decimals());
            NftContract BlindBox =  NftContract(MirrorBoxContract);
            for(uint i = 0; i < quantity_ ; i++){
                BlindBox.toMint(msg.sender);
            }
        }else{
            require(false, "Parameter error");
        }
        return true;
    }


    
    /**
    *   开锋盒       ALL
    *   tokenId_            盲盒tokenid
    *   tokenId_            盲盒合约地址
    */
    function openBlindBox(uint256[] memory tokenId_,address BlindBoxContract_) public returns(bool){
        require(tokenId_.length <= 10, "Parameter error");
        NftContract BlindBox =  NftContract(BlindBoxContract_);
        for(uint i = 0; i < tokenId_.length ; i++){
            require(BlindBox.ownerOf(tokenId_[i]) == msg.sender , "Parameter error");
            if(BlindBoxContract_ == FrontBoxContract){ 
                uint256 PoweRand = _PoweRand(0,10000);
                if(PoweRand <= 2){
                    NftContract Tesla = NftContract(TeslaSpaceXContract); 
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
                if(PoweRand > 2 && PoweRand <= 5){
                    NftContract Tesla = NftContract(TeslaRoadsterContract); 
                    require(Tesla.toMint(msg.sender), "Casting failure"); 
                }
                if(PoweRand > 5 && PoweRand <= 10){
                    NftContract Tesla = NftContract(TeslaModelsContract);
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
                if(PoweRand > 10 && PoweRand <= 100){
                    NftContract Tesla = NftContract(TeslaModelxContract);
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
                if(PoweRand > 100 && PoweRand <= 500){
                    NftContract Tesla = NftContract(TeslaModelyContract);
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
                if(PoweRand > 500){
                    NftContract Tesla = NftContract(TeslaModel3Contract);
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }

            }else if(BlindBoxContract_ == MirrorBoxContract){
                uint256 PoweRand = _PoweRand(0,100);
                if(PoweRand <= 2){
                    NftContract Tesla = NftContract(TeslaSpaceXContract);
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
                if(PoweRand > 2 && PoweRand <= 7){
                    NftContract Tesla = NftContract(TeslaRoadsterContract); 
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
                if(PoweRand > 7 && PoweRand <= 15){
                    NftContract Tesla = NftContract(TeslaModelsContract);
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
                if(PoweRand > 15 && PoweRand <= 25){
                    NftContract Tesla = NftContract(TeslaModelxContract);
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
                if(PoweRand > 25){
                    NftContract Tesla = NftContract(TeslaModelyContract);
                    require(Tesla.toMint(msg.sender), "Casting failure");
                }
            }else{
                require(false, "Parameter error");
            }
            require(BlindBox.toBurn(tokenId_[i]), "Destroy failed");
        }
        return true;
    }

    /**
    *   买股东卡       ALL
    *   ShareholderContract_         股东卡合约地址   
    *   superior_                   推荐人
    */
    function buyCard(address ShareholderContract_,address superior_) public returns(bool){
        GlodContract Glod =  GlodContract(UsdtAddress);
        Team Teams = Team(TeamContract);
        if(Teams.team(msg.sender) == address(0x00)){
            Teams.bindingWhite(msg.sender,superior_);
        }
        if(ShareholderContract_ == OrdinaryContract){
            NftContract Shareholder =  NftContract(OrdinaryContract);
            Glod.transferFrom(msg.sender,address(CollectionAddress),PriceCard * 10**Glod.decimals());
            if(!RePurchase[superior_][msg.sender]){
                if(Shareholder.balanceOf(superior_) > 0){
                    RePurchaseQuantity[superior_] += 1;
                }
                RePurchase[superior_][msg.sender] = true;
            }
            if(RePurchaseQuantity[superior_] == 5){
                Shareholder.toMint(superior_);
            }
            Shareholder.toMint(msg.sender);
        }else if(ShareholderContract_ == OriginationContract){
            NftContract Shareholder =  NftContract(OriginationContract);
            Glod.transferFrom(msg.sender,address(CollectionAddress),PriceCardVip * 10**Glod.decimals());
            Shareholder.toMint(msg.sender);
        }else{
            require(false, "Parameter error");
        }
        NftContract BlindBox =  NftContract(FrontBoxContract);
        for(uint i = 0; i < 100 ; i++){
            BlindBox.toMint(msg.sender);
        }
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