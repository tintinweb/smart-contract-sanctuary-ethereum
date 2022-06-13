//SPDX-License-Identifier: Unlicense

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./base64.sol";

//---FIX RARITY------------------------
//---CHANGE GREEN BGS------------------
//---ADD MORE LEAF COLORS--------------
//---CHANGE BLUE AND BROWN SOIL COLORS-

contract CryptoBonsai is ERC721Enumerable, Ownable {

    uint256 public maxSupply = 5000;
    uint256 public price = 0.01 ether; 
    uint256 public numTokensMinted;
    uint256 public maxPerAddress = 20; 
    uint256 public maxMint = 20; 

    bool public privateSaleIsActive = true;
 
    mapping(address => uint256) private _mintPerAddress;
    mapping(address => bool)    private _whiteList;
    mapping(address => uint256) private _whiteListPurchases;
    mapping(address => uint256) private _whiteListLimit;
    mapping(address => bool)    private _founderList;
    mapping(address => uint256) private _founderLimit;

    constructor() ERC721("BONSAIVERSE TEST GARDEN", "BONSAI") Ownable() {}

    string[8] private branchColors = ["#45283c","#663931","#b18354","#2b483f","#ab8db7","#ded7c6","#3f3e48","#914030"];
    string[8] private branchColorNames = ["Manzanita","Oak","Juniper","Yew","Lavender","Birch","Dark","Padauk"];
    string[8] private potColors = ["#663931","#6f252c","#2a2a71","#595652","#2e3d20",'#8a5303','#563c7d','#945332'];
    string[8] private potColorNames = ['Brown','Dark Red','Blue','Grey','Green',"Honey",'Violet','Clay'];
    string[8] private soilColors = ["#2c2c64","#90765b","#557a33","#827672","#7d483e","#769956","#685794","#82586f"];
    string[8] private leafColors = ["#A79AFF","#FFABAB","#84BD7E","#AFCBFF","#7B9218","#364511","#39553F","#C36F31"];
    string[8] private leafColorNames = ["Lilac","Coral","Sage","Ice Blue","Fresh Green","Forrest Green","Evergreen Green","Light Brown"];
    string[23] private colors = ['#F0CF61','#0E38B1','#EF3E4A','#FEDAC2','#B0D8DC','#C02A1B','#1FC8A9','#C886A2','#FEDCCC','#EBB9D4','#F2CB6C','#FF8FA4','#343B3F','#D1BDFF','#7B76A6','#FC6C2B','#0B64FE','#FF8B8B','#CDCDD0','#6A6AE6','#278A62','#81C272','#24872b'];
    string[23] private colorNames = ['Pale Yellow','Vivid Blue','Dusty Red','Pale Peach','Sky Aqua','Deep Red','Minty','Lipstick','Cantaloupe','Flamingo','Sand','Watermelon','Midnight','Lavender','Stone','Orange','Mario Blue','Light Rose','Grey Goose','Periwinkle','Forester','Jade','Lime'];
    string[7] private bgAccessories = ['','<path d="M0 210h20v110h30v-130h10v-10h10v-20h10v20h10v10h10v140h20v-50h50v20h10v-40h20v40h20v-20h80v20h10v-30h30v10h10v10h10v40h10v-80h10v-10h20v10h10v80h20v-110h10v-10h10v-10h10v140h10v-40h10v-60h20v110h-500zM0 230h10v110h-10zM80 200h10v150h-10zM130 290h30v20h-30zM380 260h10v10h-10zM390 280h10v10h-10zM380 300h10v10h-10zM390 320h10v10h-10zM440 240h10v110h-10zM480 310h10v30h-10z" fill="#222034" opacity="0.3" fill-rule="evenodd"/>','<path d="M40 60h40v-20h50v20h100v20h-200zM30 230h40v20h-40zM380 250h40v-10h60v20h-100zM370 70h40v-20h30v10h20v10h10v10h10v10h-110z" fill="#cbdbfc"/><path d="M30 50h10v-10h20v10h10v-20h10v-10h10v-10h30v10h10v10h10v20h10v-10h20v10h10v10h10v-10h20v10h20v10h-60v-10h-40v-20h-50v20h-30v10h-10v10h-10zM350 70h20v-10h30v-10h10v-10h20v10h10v10h10v-10h10v10h10v10h10v10h10v10h-10v-10h-10v-10h-10v-10h-10v10h-10v-10h-10v-10h-10v10h-10v10h-40v10h-20zM40 220h10v10h20v10h10v10h-10v-10h-20v-10h-10zM390 250h20v-10h20v-10h20v10h-20v10h-20zM460 220h10v10h10v20h10v10h-10v-10h-10v-10h-10z" fill="#ffffff"/><path d="M10 80h10v-10h10v10h200v-10h20v10h10v10h-250zM20 240h10v10h60v10h-60v-10h-10zM370 260h60v-10h10v10h20v-10h10v10h30v10h-130M350 80h20v10h50v-10h10v10h20v-10h20v10h10v10h-120v-10h-10z" fill="#a6b4d2"/>','<path d="M0 180h20v-10h20v-10h20v-10h20v-10h20v-10h10v-10h20v-10h20v-10h10v-10h10v-10h20v-10h10v-10h10v-10h10v-10h20v-10h30v10h10v10h10v10h20v10h10v10h10v10h10v10h10v10h20v10h20v10h10v10h10v10h10v10h20v10h20v10h20v10h20v160h-500z" fill="#5b6ee1"/><path d="M130 110h20v-10h10v-10h10v-10h20v-10h10v-10h10v-10h10v-10h20v-10h30v10h10v10h10v10h20v10h10v10h10v10h10v10h10v10h20v10h20v10h-20v-10h-40v-10h-20v-10h-10v10h-10v10h-20v-10h-10v-10h-10v-10h-20v10h-20v-10h-20v10h-30v10h-10v10h-20z" fill="#cbdbfc"/><path d="M220 70h10v-10h10v-10h20v10h-10v10h-10v10h-20zM260 80h10v10h10v10h-10v-10h-10zM270 50h10v10h10v10h10v10h-10v-10h-10v-10h-10z" fill="#5b6ee1"/><path d="M0 290h10v-10h20v-10h20v-10h10v-10h30v10h10v10h20v10h10v10h10v10h10v-10h10v-10h10v-10h20v-10h20v10h20v10h10v10h70v-10h20v-10h20v-10h20v10h20v10h20v10h20v10h10v-10h10v-10h10v-10h10v-10h20v10h10v80h-500" fill="#3f3f74"/>','<path d="M0 100h50v10h-50zM60 90h30v30h-30zM100 100h30v10h-30zM140 100h10v10h-10zM70 130h10v40h-10zM70 40h10v40h-10zM100 80h10v-10h10v-10h10v-10h20v-10h30v-10h50v-10h70v10h50v10h40v10h30v10h20v10h20v10h20v10h10v10h10v10h-10v-10h-10v-10h-20v-10h-20v-10h-20v-10h-30v-10h-40v-10h-50v-10h-70v10h-50v10h-30v10h-20v10h-10v10h-10v10h-10z" fill="#ffffff"/><path d="M100 90h10v-10h10v-10h10v-10h20v-10h30v-10h50v-10h70v10h50v10h40v10h30v10h20v10h20v10h20v10h10v10h10v10h-10v-10h-10v-10h-20v-10h-20v-10h-20v-10h-30v-10h-40v-10h-50v-10h-70v10h-50v10h-30v10h-20v10h-10v10h-10v10h-10zM40 70h10v10h10v10h-10v10h10v10h-10v10h10v10h-10v10h-10v-10h10v-10h-10v-10h10v-10h-10v-10h10v-10h-10M60 70h10v10h10v-10h10v10h10v-10h10v10h-10v10h-10v-10h-10v10h-10v-10h-10zM90 100h10v10h10v10h-10v10h10v10h-10v-10h-10v-10h10v-10h-10zM60 130h10v-10h10v10h10v10h-10v-10h-10v10h-10z" fill="#cbdbfc"/>','<path d="m130 90h10v-10h20v-10h20v-10h20v-10h100v10h20v10h20v10h20v10h10v10h-240z" fill="#ffbc00"/><path d="m110 110h280v10h10v20h-300v-20h10zM90 150h320v10h10v20h-340v-20h10z" fill-opacity=".85" fill="#ffbc00"/><path d="m70 190h360v30h-360zM70 230h360v20h-360z" fill-opacity=".70" fill="#ffbc00"/><path d="m80 260h340v20h-340zM90 290h320v10h-320z" fill-opacity=".55" fill="#ffbc00"/><path d="m100 310h300v10h-300zM110 330h280v10h-280z" fill-opacity=".4" fill="#ffbc00"/>', '<path d="M20 100h20v-20h10v20h20v10h-20v20h-10v-20h-20zM50 290h10v-10h10v-10h10v10h10v10h10v10h-10v10h-10v10h-10v-10h-10v-10h-10zM150 50h10v-10h10v-20h10v20h10v10h20v10h-20v10h-10v20h-10v-20h-10v-10h-20v-10zM430 190h10v-10h10v-10h10v10h10v10h10v10h-10v10h-10v10h-10v-10h-10v-10h-10zM390 280h10v-10h10v-20h10v20h10v10h20v10h-20v10h-10v20h-10v-20h-10v-10h-20v-10zM390 20h40v110h-40v-10h10v-10h10v-10h10v-50h-10v-10h-10v-10h-10zM50 220h10v10h-10zM20 160h10v10h-10zM100 100h10v10h-10zM260 40h10v10h-10zM330 80h10v10h-10zM50 20h10v10h-10zM460 320h10v10h-10z" fill-opacity="0.6" fill="#ffffff"/><path d="M30 100h10v-10h10v10h10v10h-10v10h-10v-10h-10zM60 290h10v-10h10v10h10v10h-10v10h-10v-10h-10zM160 50h10v-10h10v10h10v10h-10v10h-10v-10h-10zM440 190h10v-10h10v10h10v10h-10v10h-10v-10h-10zM400 280h10v-10h10v10h10v10h-10v10h-10v-10h-10zM400 20h50v10h10v10h10v10h10v50h-10v10h-10v10h-10v10h-50v-10h10v-10h10v-10h10v-50h-10v-10h-10v-10h-10z" fill="#ffffff"/>'];
    string[7] private bgAccessoriesNames = ['Cityscape','Clouds','Mt. Fuji','Comet','Sun','Stars'];
    string[9] private fgAccessories = ['','<path d="M0 349h500v151h-500z" fill="#37946e"/><path d="M120 410h260v10h10v10h-10v10h-10v10h-20v10h-200v-10h-20v-10h-10v-10h-10v-10h10zM0 490h500v10h-500zM0 450h130v10h20v10h-150zM350 460h20v-10h130v20h-150zM0 410h110v10h-10v10h-100zM390 410h110v20h-100v-10h-10zM0 370h500v20h-500z" fill="#2f7d5d"/>','<path d="M0 350h10v-10h30v-10h30v10h20v10h300v-10h10v-10h20v10h20v-10h10v10h10v10h30v-10h10v160h-500z" fill="#cbdbfc"/><path d="M0 350h10v-10h30v-10h30v10h20v10h300v-10h10v-10h20v10h20v-10h10v10h10v10h30v-10h10v40h-20v-10h-20v-10h-10v-10h-10v10h-20v-10h-20v10h-10v10h-300v-10h-20v-10h-50v10h-10v10h-10zM0 410h10v10h10v10h20v-10h10v-10h20v-10h20v10h20v10h10v10h20v-10h10v10h10v10h-30v10h-20v-10h-10v-10h-10v-10h-30v10h-10v10h-10v10h-20v-10h-10v-10h-10zM340 430h10v10h20v-10h10v-10h60v-10h20v-10h10v-10h30v20h-30v10h-10v10h-30v10h-50v10h-30v-10h-10z" fill="#ffffff"/><path d="M0 470h10v10h10v10h30v-10h20v-10h20v10h30v10h30v10h140v-10h20v-10h30v10h40v-10h20v-10h40v10h20v-10h10v-10h30v40h-500zM160 440h190v-20h10v-10h10v-10h10v10h20v10h-10v10h-20v10h-20v10h-190zM20 420h20v-10h20v-10h10v10h-20v10h-10v10h-20zM430 410h20v-10h10v-10h10v10h-10v10h-20v10h-10z" fill="#a1afcc"/>','<path d="M0 349h500v151h-500z" fill="#BEBBB7"/><path d="M120 410h260v10h10v10h-10v10h-10v10h-20v10h-200v-10h-20v-10h-10v-10h-10v-10h10z" fill="#82807B"/> ','<path d="M0 350h500v150h-500z" fill="#714835"/><path d="M0 360h20v20h-10v20h-10zM30 360h360v20h10v20h-380v-20h10zM400 360h100v40h-90v-20h-10zM0 410h80v30h-10v20h-70zM90 410h380v30h10v20h-400v-20h10zM480 410h20v50h-10v-20h-10zM0 470h170v20h-10v10h-160zM180 470h240v20h10v10h-260v-10h10zM430 470h70v30h-60v-10h-10z" fill="#aa7459"/><path d="M10 360h10v20h-10v20h-10v-20h10zM40 360h80v10h-80zM380 360h10v20h10v20h-10v-20h-10zM410 360h90v10h-90zM0 410h80v30h-10v20h-10v-20h10v-20h-70zM100 410h370v30h10v20h-10v-20h-10v-20h-360zM490 410h10v10h-10zM0 470h170v20h-10v10h-10v-10h10v-10h-160M190 470h230v20h10v10h-10v-10h-10v-10h-220zM440 470h60v10h-60z" fill="#bb8166"/><path d="M30 360h10v20h-10v10h60v-10h20v10h10v10h-100v-20h10zM50 370h20v10h-20zM400 360h10v20h10v10h20v-10h20v10h40v10h-90v-20h-10zM380 390h10v10h-10zM480 370h20v10h-20zM0 450h60v10h-60zM10 430h40v10h-40zM90 410h10v30h-10v10h380v10h-390v-20h10zM110 430h30v10h-30zM370 430h80v10h-80zM480 410h10v30h10v20h-10v-20h-10zM0 480h50v10h-50zM80 490h50v10h-50zM180 470h10v20h-10v20h-10v-20h10zM200 490h30v10h-30zM250 480h80v10h-80zM430 470h10v20h10v10h-10v-10h-10M460 490h30v10h-30z" fill="#93654e"/>','<path d="M0 350h500v150h-500z" fill="#639bff"/><path d="M0 370h70v10h-70zM60 400h40v10h-40zM0 440h40v10h-40zM60 460h20v10h-20zM0 480h40v10h-40zM70 480h360v10h-360zM430 360h70v10h-70zM410 390h60v10h-60zM440 430h40v10h-40zM430 460h40v10h-40zM480 480h20v10h-20z" fill="#5b6ee1"/><path d="M100 340h300v30h10v40h10v40h10v30h-360v-30h10v-40h10v-40h10z" fill="#eec39a"/><path d="M100 360h300v10h-300zM90 390h320v20h-320zM80 430h340v20h-340zM70 470h360v10h-360z" fill="#d9a066"/><path d="M130 410h10v40h-10v30h-20v-30h10v-30h10zM240 440h20v40h-20zM360 410h10v10h10v30h10v30h-20v-30h-10z" fill="#a4794e"/>','<path d="M0 350h20v-10h20v-10h60v10h20v10h250v-20h50v10h30v10h30v-10h10v-10h10v170h-500z" fill="#d9a066"/> <path d="M0 350h20v-10h20v-10h30v10h-10v10h-10v10h-20v10h-20v10h-10zM0 430h20v-10h10v-10h40v10h10v10h10v10h10v10h-10v-10h-10v-10h-10v-10h-20v10h-10v10h-40zM90 480h20v-10h20v-10h40v10h20v10h20v10h-20v-10h-20v-10h-20v10h-20v10h-40zM350 480h20v-10h30v10h10v10h-10v-10h-20v10h-30zM350 440h20v-10h20v-10h30v-10h40v10h20v10h20v10h-20v-10h-20v-10h-20v10h-30v10h-20v10h-40zM170 440h160v10h-160zM450 360h20v-10h10v-10h10v-10h10v20h-10v10h-20v10h-20zM370 330h30v10h-10v10h-10v-10h-10z" fill="#b17d48"/>','<path d="M70 360h360v10h-20v10h20v10h-20v10h30v10h-20v10h20v10h-20v10h30v10h-20v10h20v10h-20v10h30v10h-420v-10h30v-10h-20v-10h20v-10h-20v-10h30v-10h-20v-10h20v-10h-20v-10h30v-10h-20v-10h20v-10h-20z" fill="#f4dcc5"/><path d="M100 370h300v30h10v40h10v40h-340v-40h10v-40h10z" fill="#ac3232"/><path d="M110 380h10v30h-10zM380 380h10v30h-10zM100 410h10v40h-10zM390 410h10v40h-10zM90 450h10v10h300v-10h10v20h-320z" fill="#df7126"/><path d="M130 410h10v10h-10zM360 410h10v10h-10zM120 420h10v20h240v-20h10v30h-260z" fill="#3f3f74"/>', '<path d="M30 350h30v10h-10v10h40v10h-10v10h-10v10h40v10h-10v20h-10v10h40v20h-10v20h-10v10h50v10h-50v-10h-50v-10h10v-20h10v-10h10v-10h-40v-10h10v-20h10v-10h-40v-10h10v-10h10v-10h-30v-10h10zM0 370h20v10h-10v10h-10zM0 400h30v10h-10v10h-10v20h-10zM0 450h10v-10h40v10h-10v10h-10v10h-10v20h-20zM20 490h40v10h-40zM100 350h20v20h-30v-10h10zM110 390h10v10h-10zM130 430 h10v-10h10v10h10v10h-30zM110 490h50v-30h10v-20h50v10h-10v40h50v-50h40v10h10v40h50v-30h-10v-20h-10v-10h10v10h50v20h10v20h10v10h50v-10h-10v-10h-10v-20h-10v-10h40v10h10v10h10v30h-30v10h-50v-10h-60v10h-50v-10h-50v10h-50v-10zM380 400h40v-10h-10v-10h-10v-10h-20v-20h10v10h10v10h30v-10h-10v-10h30v10h10v10h-30v10h10v10h10v10h-30v10h10v20h10v10h-40v-10h-10v-20h-10zM450 400h30v-10h-10v-10h-10v-10h30v-10h-10v-10h20v20h-10v10h10v20h-20v10h10v10h10v20h-20v-10h-10v-10h-10v-10h-10z" fill="#ffffff"/>'];
    string[9] private fgAccessoriesNames = ['','Fresh Cut Grass','In The Clouds','Light','Hardwood Floor','Bamboo Raft','Sand Dunes','Rug', 'Checkered Floor'];
    string[12] private accessories = ['','<path d="M110 240h10v10h10v10h10v40h-10v10h-10v10h-10v10h-20v-20h10v-10h10v-10h10v-20h-10v-10h-10v-10h10zM190 200h10v10h10v10h-10v10h-10v20h10v10h10v10h10v20h-20v-10h-10v-10h-10v-10h-10v-40h10v-10h10zM380 220h10v10h10v10h-10v10h-10v10h-10v20h10v10h10v10h10v20h-20v-10h-10v-10h-10v-10h-10v-40h10v-10h10v-10h10z" fill="#fbf236"/><path d="M110 240h10v10h10v10h10v40h-10v10h-10v10h-10v10h-10v-10h10v-10h10v-10h10v-40h-10v-10h-10v-10zM190 200h10v10h-10v10h-10v40h10v10h10v10h10v10h-10v-10h-10v-10h-10v-10h-10v-40h10v-10h10v-10zM380 220h10v10h-10v10h-10v10h-10v40h10v10h10v10h10v10h-10v-10h-10v-10h-10v-10h-10v-40h10v-10h10v-10h10v-10z" fill="#dad116"/><path d="M250 90h50v10h10v50h-10v10h-50v-10h-10v-50h10z" fill="#8f563b"/><path d="M270 100h30v10h10v20h10v20h-50v-10h-10v-30h10zM230 120h20v20h-20z" fill="#eec39a"/><path d="M270 120h10v10h-10zM300 120h10v10h-10z" fill="#222034"/><path d="M270 150 h30v10h-30z" fill="#663931"/>','<path d="M200 130v-70h10v10h10v20h10v10h10v-10h10v-20h10v-10h10v10h10v20h10v10h10v-10h10v-20h10v-10h10v70h-10v20h-20v-20h-20v10h-10v10h-40v-20z" fill="#1f3be3"/><path d="M200 130v-70h10v50h10v10h10v10h90v20h-20v-20h-20v10h-10v10h-40v-20zM230 100h10v-10h10v-20h10v20h-10v10h-10v10h-10zM290 100h10v-10h10v-20h10v20h-10v10h-10v10h-10z" fill="#1e35c3"/><path d="M200 160h10v-10h10v-10h30v10h10v10h10v-10h10v-10h30v10h10v10h10v10h-10v10h-10v10h-30v-10h-10v-10h-10v10h-10v10h-30v-10h-10v-10h-10z" fill="#2a2933"/><path d="M220 150h30v30h-10v-10h-10v10h-10zM280 150h30v30h-10v-10h-10v10h-10z" fill="#9badb7"/>','<path d="M200 60h10v10h10v20h10v10h10v-10h10v-20h10v-10h10v10h10v20h10v10h10v-10h10v-20h10v-10h10v70h-10v20h-10v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-30h-20v20h-20z" fill="#1da826"/><path d="M200 60h10v50h10v20h-20zM230 100h10v10h-10zM240 90h10v10h-10zM250 70h10v20h-10zM290 100h10v10h-10zM300 90h10v10h-10zM310 70h10v20h-10zM240 130h40v10h-10v10h-20v10h-10zM300 130h20v20h-10v-10h-10z" fill-opacity="0.15" fill="#000000"/>','<path d="M140 130 h10v-10h10v10h10v30h-10v10h-10v-10h-10zM120 230 h10v-10h10v10h10v30h-10v10h-10v-10h-10zM180 190 h10v-10h10v10h10v30h-10v10h-10v-10h-10zM270 160 h10v-10h10v10h10v30h-10v10h-10v-10h-10zM360 170 h10v-10h10v10h10v30h-10v10h-10v-10h-10zM340 240 h10v-10h10v10h10v30h-10v10h-10v-10h-10z" fill="#fbf236"/><path d="M150 120h10v10h10v30h-10v10h-10v-10h10v-30h-10zM130 220h10v10h10v30h-10v10h-10v-10h10v-30h-10zM190 180h10v10h10v30h-10v10h-10v-10h10v-30h-10zM280 150h10v10h10v30h-10v10h-10v-10h10v-30h-10zM370 160h10v10h10v30h-10v10h-10v-10h10v-30h-10zM350 230h10v10h10v30h-10v10h-10v-10h10v-30h-10z" fill="#c1b918"/>','<path d="M220 80h80v50h-80z" fill="#c8a98c"/><path d="M210 80h30v10h-10v10h-10v10h-10z M280 80h30v30h-10v-10h-10v-10h-10zM250 110h20v10h10v20h-40v-20h10z" fill="#433431"/><path d="M250 140h20v10h-20z" fill="#d85780"/><path d="M250 120h20v-20h10v20h-10v10h-20zM230 100h10v20h-10z" fill="#222034"/><path d="M240 100h10v20h-10zM280 100h10v20h-10z" fill="#ffffff"/>','<path d="M180 220h30v-20h60v20h10v-20h60v60h-60v-30h-10v30h-60v-30h-20v20h-10z" fill="#639bff"/> <path d="M220 210h20v40h-20zM290 210h20v40h-20z" fill="#ffffff"/> <path d="M240 210h20v40h-20zM310 210h20v40h-20z" fill="#000000"/>','<path d="M200 60h10v10h10v20h10v10h10v-10h10v-20h10v-10h10v10h10v20h10v10h10v-10h10v-20h10v-10h10v70h-10v20h-10v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-30h-20v20h-20z" fill="#76428a"/><path d="M200 60h10v50h10v20h-20zM230 100h10v10h-10zM240 90h10v10h-10zM250 70h10v20h-10zM290 100h10v10h-10zM300 90h10v10h-10zM310 70h10v20h-10zM240 130h40v10h-10v10h-20v10h-10zM300 130h20v20h-10v-10h-10z" fill-opacity="0.15" fill="#000000"/>','<path d="M150 200h240v20h-10v10h-10v10h-10v10h-60v-10h-10v-10h-10v-10h-20v10h-10v10h-10v10h-60v-10h-10v-10h-10v-10h-10z" fill="#222034"/><path d="M200 230h10v-10h10v-10h10v10h-10v10h-10v10h-10zM220 230h10v-10h10v-10h10v10h-10v10h-10v10h-10zM320 230h10v-10h10v-10h10v10h-10v10h-10v10h-10zM340 230h10v-10h10v-10h10v10h-10v10h-10v10h-10z" fill="#ffffff"/>','<path d="M200 110h10v-10h50v-30h40v60h-20v10h-10v10h-20v-10h-10v-30h-20v20h-10v-10h-10z" fill="#ffffff"/> <path d="M250 50h10v10h10v10h-10v10h-10z" fill="#dc3636"/> <path d="M270 80h10v10h-10zM290 80h10v10h-10z" fill="#000000"/> <path d="M300 90h20v10h-10v10h-10z" fill="#d9a066"/>', '<path d="m110 140h10v-10h20v-10h20v-10h20v-10h20v-10h20v-10h20v-10h20v10h20v10h20v10h20v10h20v10h20v10h20v10h10v10h-280z" fill="#b5895c"/><path d="m180 120h10v10h10v-10h10v-10h-10v-10h10v10h10v-10h10v-10h10v-10h10v-10h10v10h20v10h20v10h20v10h20v10h20v20h-40v-10h20v-10h-20v10h-20v10h-70v-10h-20v10h-20v-10h-10v10h-20v-10h20z" fill="#d9a066"/><path d="m240 100h20v-10h20v10h-20v10h-20zM260 120h20v-10h20v10h-20v10h-20z" fill="#b5895c"/><path d="m110 150h270v10h-270z" fill-opacity="0.3" fill="#000000"/>', '<path d="M110 240h10v40h-10zM110 300h10v40h-10zM160 260h10v40h-10zM110 300h10v40h-10zM210 230h10v40h-10zM320 270h10v40h-10zM380 230h10v40h-10zM380 290h10v40h-10z" fill="#9d97a0"/> <path d="M120 230h10v10h10v10h-20zM120 270h20v10h-20zM120 290h10v10h10v10h-20zM120 330h20v10h-20zM120 350h10v10h-10z M170 250h10v10h10v10h-20zM330 300h20v10h-20zM330 320h10v10h-10zM330 260h10v10h10v10h-20zM220 260h20v10h-20zM220 280h10v10h-10zM220 220h10v10h10v10h-20zM170 290h20v10h-20zM170 310h10v10h-10zM390 220h10v10h10v10h-20zM390 260h20v10h-20zM390 280h10v10h10v10h-20zM390 320h20v10h-20zM390 340h10v10h-10z" fill="#847e87"/> <path d="M130 250h10v20h-10zM120 280h10v10h-10zM130 310h10v20h-10zM120 340h10v10h-10z M180 270h10v20h-10zM170 300h10v10h-10zM170 240h10v10h-10zM220 210h10v10h-10zM230 240h10v20h-10zM220 270h10v10h-10zM330 250h10v10h-10zM340 280h10v20h-10zM330 310h10v10h-10zM390 210h10v10h-10zM400 240h10v20h-10zM390 270h10v10h-10zM400 300h10v20h-10zM390 330h10v10h-10z" fill="#696a6a"/>'];
    string[12] private accessoriesNames = ['','Monkey Madness','Partyhat & Specs','Green Partyhat','Lemons','Nellie','Noun Glasses','Purple Party Hat','Deal With It','Chicken Fren', 'Rice Hat', 'chains'];
    string[5] private potAccessories = ['','<path d="M140 360h10v30h10v-10h10v10h10v-30h10v30h-10v10h-10v-10h-10v10h-10v-10h-10zM200 380h10v-10h10v10h10v10h-10v-10h-10v10h-10zM200 390h30v20h-10v-10h-10v10h-10zM240 380h10v-10h20v10h-20v20h10v-10h20v10h-10v10h-20v-10h-10zM290 380h10v-10h10v10h10v-10h10v10h10v30h-10v-30h-10v10h-10v-10h-10v30h-10zM350 360h10v40h-10z" fill-opacity="0.4" fill="#ffffff"/>','<path d="M140 390h10v10h10v10h10v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h10v-10h10v-10h10v10h-10v10h-10v10h-10v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-10v-10h-10v-10h-10z" fill="#a6233f"/><path d="M140 380h10v10h10v10h10v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h10v-10h10v-10h10v10h-10v10h-10v10h-10v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-10v-10h-10v-10h-10z" fill="#252d9c"/><path d="M140 370h10v10h10v10h10v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h10v-10h10v-10h10v10h-10v10h-10v10h-10v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-10v-10h-10v-10h-10zM130 380h10v10h-10zM360 380h10v10h-10z" fill="#3fb1d4"/>','<path d="M140 390h10v10h10v10h10v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h10v-10h10v-10h10v10h-10v10h-10v10h-10v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-10v-10h-10v-10h-10z" fill="#222034"/><path d="M140 380h10v10h10v10h10v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h10v-10h10v-10h10v10h-10v10h-10v10h-10v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-10v-10h-10v-10h-10z" fill="#d25c0b"/><path d="M140 370h10v10h10v10h10v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h20v-10h10v-10h20v10h10v10h10v-10h10v-10h10v10h-10v10h-10v10h-10v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-20v-10h-10v-10h-20v10h-10v10h-10v-10h-10v-10h-10zM130 380h10v10h-10zM360 380h10v10h-10z" fill="#fbb236"/>','<path d="M160 300h70v10h-20v10h-10v10h10v10h10v10h60v-10h10v-10h10v-10h-10v-10h-10v-10h60v10h20v10h10v10h10v10h10v20h-10v50h10v20h-10v10h-10v10h-20v10h-30v10h-140v-10h-30v-10h-20v-10h-10v-10h-10v-20h10v-50h-10v-20h10v-10h10v-10h10v-10h20z" fill="#dd8e36"/><path d="M110 340h10v-10h10v-10h10v-10h20v-10h30v10h-10v10h-20v10h-10v20h10v10h20v10h30v10h110v10h-140v-10h-30v-10h-20v-10h-20zM110 410h20v10h20v10h30v10h120v10h-120v-10h-30v-10h-20v-10h-10v10h10v10h20v10h30v10h140v10h-140v-10h-30v-10h-20v-10h-10v-10h-10zM210 300h20v10h-20v10h-10v10h10v10h10v10h60v-10h10v-10h10v-10h-10v-10h-10v-10h10v10h10v10h10v10h-10v10h-10v10h-10v10h-60v-10h-10v-10h-10v-10h-10v-10h10v-10h10z" fill="#d27207"/><path d="M120 360h10v10h20v10h30v10h140v-10h30v-10h20v-10h10v10h-10v10h-20v10h-30v10h-140v-10h-30v-10h-20v-10h-10z" fill="#dd2323"/><path d="M120 380h10v10h20v10h30v10h140v-10h30v-10h20v-10h10v20h-10v10h-20v10h-30v10h-140v-10h-30v-10h-20v-10h-10z" fill="#663931"/><path d="M120 370h10v10h20v10h30v10h140v-10h30v-10h20v-10h10v10h-10v10h-20v20h-10v-10h-20v10h-10v10h-10v-10h-50v10h-20v-10h-20v10h-10v-10h-20v-10h-10v10h-10v-10h-10v-10h-20v-10h-10z" fill="#f9be57"/><path d="M120 400h10v10h20v10h30v10h140v-10h30v-10h20v-10h10v10h-10v10h-20v10h-30v10h-140v-10h-30v-10h-20v-10h-10z" fill="#6abe30"/><path d="M160 330h10v10h-10zM190 300h10v10h-10zM180 350h10v10h-10zM200 340h10v10h-10zM220 370h10v10h-10zM250 360h10v10h-10zM290 370h10v10h-10zM300 340h10v10h-10zM330 360h10v10h-10zM360 340h10v10h-10zM340 320h10v10h-10zM310 300h10v10h-10z" fill="#eec39a"/>'];
    string[5] private potAccessoriesNames = ['','WAGMI','Wavey Blue','Wavey Orange','Borgor'];

    struct cryptoBonsai {
        uint256 berryColor;
        uint256 leafColor;
        uint256 backgroundColor;
        uint256 potColor;
        uint256 branchColor;
        uint256 bgAccessories;
        uint256 fgAccessories;
        uint256 accessories;
        uint256 potAccessories;
    }

    function randomBonsai(uint256 tokenId) internal view returns (cryptoBonsai memory) {
        cryptoBonsai memory bonsai;

        bonsai.berryColor = getAColor(tokenId, "FLOWER");
        bonsai.leafColor = getLeafColor(tokenId, "LEAF");
        bonsai.branchColor = getBranchColor(tokenId, "BRANCH");
        bonsai.backgroundColor = getAColor(tokenId, "BGC");
        bonsai.potColor = getPotColor(tokenId, "POT");
        bonsai.bgAccessories = getBgAcc(tokenId);
        bonsai.fgAccessories = getFgAcc(tokenId);
        bonsai.accessories = getAccessories(tokenId);
        bonsai.potAccessories = getPotAccessories(tokenId);

        return bonsai;
    }
    
    function getTraits(cryptoBonsai memory bonsai) internal view returns (string memory) {
        string[20] memory parts;
        
        parts[0] = ', "attributes": [{"trait_type": "Background Color","value": "';
        parts[1] = colorNames[bonsai.backgroundColor];
        parts[2] = '"}, {"trait_type": "Flowers","value": "';
        parts[3] = colorNames[bonsai.berryColor];
        parts[5] = '"}, {"trait_type": "Leaf Color","value": "';
        parts[6] = leafColorNames[bonsai.leafColor];
        parts[7] = '"}, {"trait_type": "Branch","value": "';
        parts[8] = branchColorNames[bonsai.branchColor];
        parts[9] = '"}, {"trait_type": "Pot Color","value": "';
        parts[10] = potColorNames[bonsai.potColor];
        parts[11] = '"}, {"trait_type": "Accessories","value": "';
        parts[12] = accessoriesNames[bonsai.accessories];
        parts[13] = '"}, {"trait_type": "Accessories","value": "';
        parts[14] = fgAccessoriesNames[bonsai.fgAccessories];
        parts[15] = '"}, {"trait_type": "Accessories","value": "';
        parts[16] = bgAccessoriesNames[bonsai.bgAccessories];
        parts[17] = '"}, {"trait_type": "Accessories","value": "';
        parts[18] = potAccessoriesNames[bonsai.potAccessories];
        parts[19] = '"}] ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7], parts[8]));
                      output = string(abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15]));
                      output = string(abi.encodePacked(output, parts[16], parts[17], parts[18], parts[19]));
        return output;
    }

    /* UTILITY FUNCTIONS FOR PICKING RANDOM TRAITS */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function getNum(uint256 tokenId, string memory keyPrefix, uint256 minNum, uint256 maxNum) internal view returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, Strings.toString(tokenId), minNum, maxNum, msg.sender, block.timestamp, block.difficulty)));
        uint256 num = rand % (maxNum - minNum + 1) + minNum;
        return num;
    }
    
    function getAColor(uint256 tokenId, string memory seed) internal view returns (uint256) {
        return getNum(tokenId, seed, 0, 22);
    }

    function getPotColor(uint256 tokenId, string memory seed) internal view returns (uint256) {
        return getNum(tokenId, seed, 0, 7);
    }

    function getBranchColor(uint256 tokenId, string memory seed) internal view returns (uint256) {
        return getNum(tokenId, seed, 0, 7);
    }

    function getLeafColor(uint256 tokenId, string memory seed) internal view returns (uint256) {
        return getNum(tokenId, seed, 0, 7);
    }
    
    function getFgAcc(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BACKGROUND TYPE", Strings.toString(tokenId))));
        uint256 gt = rand % 101; 
        uint256 fgAcc = 0;

        if (gt > 30 && gt <= 40) { fgAcc = 1; }
        if (gt > 41 && gt <= 50) { fgAcc = 2; }
        if (gt > 51 && gt <= 60) { fgAcc = 3; }
        if (gt > 61 && gt <= 70) { fgAcc = 4; }
        if (gt > 71 && gt <= 80) { fgAcc = 5; }
        if (gt > 81 && gt <= 90) { fgAcc = 6; }
        if (gt > 91 && gt <= 95) { fgAcc = 7; }
        if (gt > 96 && gt <= 100) { fgAcc = 8; }

        return fgAcc;
    }

    function getAccessories(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("Accessories", Strings.toString(tokenId))));
        uint256 gt = rand % 101; 
        uint256 Accessories = 0;

        if (gt > 10 && gt <= 19) { Accessories = 1; }
        if (gt > 20 && gt <= 29) { Accessories = 2; }
        if (gt > 30 && gt <= 39) { Accessories = 3; }
        if (gt > 40 && gt <= 50) { Accessories = 4; }
        if (gt > 51 && gt <= 60) { Accessories = 5; }
        if (gt > 61 && gt <= 70) { Accessories = 6; }
        if (gt > 71 && gt <= 80) { Accessories = 7; }
        if (gt > 81 && gt <= 85) { Accessories = 8; }
        if (gt > 86 && gt <= 90) { Accessories = 9; }
        if (gt > 91 && gt <= 95) { Accessories = 10; }
        if (gt > 96 && gt <= 100) { Accessories = 11; }

        return Accessories;
    }

    function getPotAccessories(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("POT ACCESSORIES", Strings.toString(tokenId))));
        uint256 gt = rand % 101; 
        uint256 potAcc = 0;

        if (gt > 50 && gt <= 60) { potAcc = 1; }
        if (gt > 61 && gt <= 70) { potAcc = 2; }
        if (gt > 71 && gt <= 80) { potAcc = 3; }
        if (gt > 81 && gt <= 90) { potAcc = 4; }

        return potAcc;
    }

    function getBgAcc(uint256 tokenId) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked("BACKGROUND ACCESSORIES", Strings.toString(tokenId))));
        uint256 gt = rand % 101; 
        uint256 BgAcc = 0;

        if (gt > 50 && gt <= 60) { BgAcc = 1; }
        if (gt > 61 && gt <= 70) { BgAcc = 2; }
        if (gt > 71 && gt <= 85) { BgAcc = 3; }
        if (gt > 86 && gt <= 92) { BgAcc = 4; }
        if (gt > 93 && gt <= 100) { BgAcc = 5; }

        return BgAcc;
    }
    
    /* IMAGE BUILDING FUNCTIONS */
    function getBonsaiSVG(cryptoBonsai memory bonsai) internal view returns (string memory) {
        string[25] memory parts;

        parts[0] = '<svg viewBox="0 0 500 500" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">';
        parts[1] = '<path d="M0 0h500v500h-500z" fill="';
        parts[2] = colors[bonsai.backgroundColor];
        parts[3] = '"/>';
        parts[4] = '<path d="M0 350h500v150h-500z" fill="#222034"/>';
        parts[5] = bgAccessories[bonsai.bgAccessories];
        parts[6] = fgAccessories[bonsai.fgAccessories];
        parts[7] = '<path d="M160 110h20v10h10v10h30v-20h20v30h10v10h20v-10h10v-10h20v10h10v10h10v-20h20v20h40v10h10v10h10v10h10v20h-10v10h-10v10h-10v10h-20v20h-40v-30h10v-10h10v-10h10v-10h-10v-10h-10v10h-10v10h-10v10h-30v-10h-10v-10h-40v-10h-10v-10h-30v10h10v20h10v10h10v20h-10v10h-10v10h-20v-10h-20v10h-20v-10h-10v-10h-10v10h-10v-10h-10v-20h10v-10h10v-20h-10v-10h-10v-20h10v-10h10v-10h30v-10h10z" fill="';
        parts[8] = leafColors[bonsai.leafColor];
        parts[9] = '"/><path d="M170 110h10v10h-10zM180 120h10v10h-10zM160 120h10v10h-10zM150 130h10v10h-10zM130 130h10v10h-10zM170 130h10v10h-10zM200 130h10v10h-10zM230 130h10v10h-10zM240 140h10v10h-10zM250 150h10v10h-10zM310 150h10v10h-10zM300 140h10v10h-10zM290 130h10v10h-10zM320 140h10v10h-10zM330 160h10v10h-10zM340 150h10v10h-10zM360 150h20v10h-20zM380 160h10v10h-10zM390 170h10v10h-10zM400 180h10v10h-10zM390 190h10v10h-10z" fill-opacity="0.15" fill="#ffffff"/><path d="M110 140h10v20h-10zM100 160h10v10h-10zM110 170h10v10h-10zM120 180h10v10h-10zM130 190h10v10h-10zM110 200h20v10h-20zM100 210h10v10h20v10h-10v10h-10v-10h-10zM130 230h20v10h10v10h-20v-10h-10zM180 240h10v10h-10zM170 230h10v10h-10zM160 220h10v10h-10zM150 210h10v10h-10zM160 200h10v10h-10zM150 190h10v10h-10zM170 210h10v10h-10zM180 220h10v10h-10zM190 210h10v10h-10zM200 200h10v10h-10zM210 210h10v20h-10zM200 230h10v10h-10zM190 180h10v10h-10zM180 170h10v10h-10zM150 160h10v10h-10zM140 150h10v10h-10zM180 150h10v10h-10zM170 140h10v10h-10zM210 160h10v10h-10zM230 170h10v10h-10zM240 180h10v10h-10zM250 170h10v10h-10zM260 180h10v10h-10zM270 190h10v10h-10zM280 200h10v10h-10zM290 190h10v10h-10zM300 200h10v10h-10zM310 190h10v10h-10zM280 170h10v10h-10zM270 160h10v10h-10zM350 180h10v10h-10zM360 190h10v10h-10zM350 200h10v10h-10zM340 210h10v10h-10zM320 220h10v10h10v20h-20zM360 220h20v10h-20zM380 210h10v10h-10zM160 170h10v10h-10z" fill-opacity="0.2" fill="#000000"/>'; //leaf base
        parts[10] = '<path d="M120 150h10v10h10v10h-20zM120 210h20v20h-10v-10h-10zM180 190h20v10h-10v10h-10zM160 160h10v-10h10v20h-20zM180 130h20v20h-10v-10h-10zM220   110h20v20h-10v-10h-10zM220 160h10v-10h10v20h-20zM280 150h10v10h10v10h-20zM300 180h10v-10h10v20h-20zM320 130h20v20h-10v-10h-10zM360 170h20v20h-10v-10h-10zM350 230h10v20h-20v-10h10z" fill="';
        parts[11] = colors[bonsai.berryColor];
        parts[12] = '"/> <path d="M130 210h10v10h-10zM170 150h10v10h-10zM190 130h10v10h-10zM230 110h10v10h-10zM230 150h10v10h-10zM310 170h10v10h-10zM330 130h10v10h-10zM370 170h10v10h-10z" fill-opacity="0.25" fill="#ffffff"/> <path d="M120 160h10v10h-10zM130 220h10v10h-10zM180 200h10v10h-10zM160 160h10v10h-10zM220 160h10v10h-10zM280 160h10v10h-10zM340 240h10v10h-10z" fill-opacity="0.2" fill="#000000"/>';//berry shadows
        parts[13] = '<path d="M160 300h180v10h10v10h10v10h10v10h10v60h-10v10h-10v10h-10v10h-10v10h-180v-10h-10v-10h-10v-10h-10v-10h-10v-60h10v-10h10v-10h10v-10h10z" fill="';
        parts[14] = potColors[bonsai.potColor];
        parts[15] = '"/> <path d="M170 310h10v10h10v20h10v10h10v10h-20v-10h-10v-20h-10zM210 360h80v10h-80zM290 350h10v10h-10zM300 340h10v10h-10zM310 320h10v20h-10zM320 310h10v10h-10zM140 340h10v20h10v20h10v10h20v10h10v-10h10v10h10v-10h10v10h10v-10h10v10h10v-10h10v10h10v-10h10v10h10v10h10v10h10v-10h10v-10h20v10h-10v10h-10v10h-160v-10h-10v-10h-10v-10h-10v-10h-10v-40h10zM350 390h10v10h-10zM360 380h10v10h-10zM310 400h10v10h-10zM300 390h10v10h-10zM320 390h10v10h-10z" fill-opacity="0.09" fill="#ffffff"/> <path d="M160 320h10v10h10v20h10v10h20v10h80v-10h10v-10h20v10h10v10h10v10h10v-10h10v20h-10v10h-20v-10h-10v10h-10v-10h-10v10h-10v-10h-10v10h-10v-10h-10v10h-10v-10h-10v10h-10v-10h-10v10h-10v-10h-10v10h-10v-10h-20v-10h-10v-20h-10v-30h10zM300 400h10v10h-10zM310 360h10v10h-10zM320 400h10v10h-10zM320 340h10v10h-10zM330 350h10v10h-10zM340 360h10v10h-10zM350 350h10v10h-10zM340 340h10v10h-10zM330 330h10v10h-10zM310 410h10v10h-10z" fill-opacity="0.2" fill="#ffffff"/> <path d="M310 340h10v10h-10zM320 350h10v10h-10zM330 360h10v10h-10zM340 370h10v10h-10zM350 360h10v-10h10v30h-10v-10h-10zM340 350h10v10h-10zM330 340h10v10h-10zM320 320h20v10h-10v10h-10zM340 330h10v10h-10zM350 340h10v10h-10z" fill-opacity="0.35" fill="#ffffff"/>';//pot highlights
        parts[16] = '<path d="M190 170h30v10h10v10h10v10h20v10h10v10h10v20h10v-10h10v-20h10v-10h10v-10h10v-10h10v10h10v10h-10v10h-10v10h-10v20h-10v20h-10v10h-10v10h-10v40h10v10h-10v10h-60v-10h-10v-10h10v-10h10v-10h10v-30h10v-10h10v-20h-10v-10h-10v-10h-10v-10h-10v-10h-10v-10h-10v-10h-10z" fill="';
        parts[17] = branchColors[bonsai.branchColor];
        parts[18] = '"/> <path d="M210 170h10v10h-10zM220 180h10v10h-10zM230 190h10v10h-10zM250 200h10v10h-10zM260 210h10v10h-10zM270 220h10v10h-10zM310 230h10v10h-10zM330 180h10v10h-10zM340 190h10v10h-10zM300 250h10v10h-10zM290 260h10v10h-10zM280 270h10v10h-10zM270 280h10v40h-10z" fill-opacity="0.25" fill="#ffffff"/> <path d="M190 170h10v10h-10zM200 180h10v10h-10zM210 190h10v10h-10zM220 200h10v10h-10zM230 210h10v10h-10zM260 240h10v20h-10zM250 260h10v10h-10zM240 270h10v40h-10v10h10v10h-10v10h-20v-10h-10v-10h10v-10h10v-10h10zM250 230h10v10h-10zM300 210h10v20h-10zM310 200h10v10h-10zM320 190h10v10h-10zM240 220h10v10h-10zM290 230h10v10h-10z" fill-opacity="0.25" fill="#000000"/>';//branch shadows
        parts[19] = '<path d="M230 340h50v10h-50zM280 330h10v10h-10zM290 320h10v10h-10zM280 310h10v10h-10zM220 340h10v10h-10zM210 330h10v10h-10zM200 320h10v10h-10zM210 310h10v10h-10z" fill="';
        parts[20] = soilColors[bonsai.leafColor];
        parts[21] = '"/> <path d="M230 340h10v10h-10zM250 340h30v10h-30zM280 330h10v10h-10zM290 320h10v10h-10zM280 310h10v10h-10z" fill-opacity="0.2" fill="#000000"/>';//soil shadows
        parts[22] = potAccessories[bonsai.potAccessories];
        parts[23] = accessories[bonsai.accessories];
        parts[24] = '</svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6], parts[7]));
        output = string(abi.encodePacked(output, parts[8], parts[9], parts[10], parts[11], parts[12], parts[13], parts[14], parts[15]));
        output = string(abi.encodePacked(output, parts[16], parts[17], parts[18], parts[19], parts[20], parts[21], parts[22], parts[23]));
        output = string(abi.encodePacked(output, parts[24]));

        return output;
    }

    function tokenURI(uint tokenId) override public view returns (string memory) {
        cryptoBonsai memory bonsai = randomBonsai(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Bonsai #', Strings.toString(tokenId), '", "description": "Bonsais are 100% on chain and randomly generated to bring tranqulity to your blockchain. Very zen.", ', '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getBonsaiSVG(bonsai))), '"', getTraits(bonsai), '}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function addToWhitelist(uint256 amount, address[] calldata entries) onlyOwner external {
        for(uint i=0; i<entries.length; i++){
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!_whiteList[entry], "DUPLICATE_ENTRY");
            _whiteList[entry] = true;
            _whiteListLimit[entry] = amount;
        }
    }

    function addToFounderList(uint256 amount, address[] calldata founder) onlyOwner external {
        for(uint i=0; i<founder.length; i++) {
            address founders = founder[i];
            require(founders != address(0), "NULL_ADDRESS");
            require(!_founderList[founders], "DUPLICATE_ENTRY");
            _founderList[founders] = true;
            _founderLimit[founders] = amount;
        }
    }

    function removeFromWhitelist(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            _whiteList[entry] = false;
        }
    }

    function mint(address destination, uint256 amountOfTokens) private {
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(price * amountOfTokens == msg.value, "ETH amount is incorrect");
        require(_mintPerAddress[msg.sender] + amountOfTokens <= maxPerAddress,  "You can't exceed this wallet's minting limit");
        require(amountOfTokens <= maxMint, "Cannot purchase this many tokens in a transaction");
        
        if (privateSaleIsActive) {
            require(_whiteList[msg.sender], "Buyer not whitelisted for this private sale");
            require(_whiteListPurchases[msg.sender] + amountOfTokens <= _whiteListLimit[msg.sender], "Cannot mint more than 5 Bonsais during presale");
            _whiteListPurchases[msg.sender] = _whiteListPurchases[msg.sender] + amountOfTokens;
        }

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
            _mintPerAddress[msg.sender] += 1;
        }
    }

    function founderMint(uint256 amountOfTokens) public {
        require(_founderList[msg.sender], "Buyer is not a founder");
        require(totalSupply() < maxSupply, "All tokens have been minted");
        require(totalSupply() + amountOfTokens <= maxSupply, "Minting would exceed max supply");
        require(amountOfTokens > 0, "Must mint at least one token");
        require(amountOfTokens <= _founderLimit[msg.sender], "Cannot purchase this many tokens in a transaction"); 

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(msg.sender, tokenId);
            numTokensMinted += 1;
            _mintPerAddress[msg.sender] += 1;
        }
    }
    
    function mintBonsai(uint256 amountOfTokens) public payable virtual {
        mint(_msgSender(),amountOfTokens);
    }

    function enablePublicSale() public onlyOwner {
        privateSaleIsActive = false;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}