pragma solidity^0.8.13;//SPDX-License-Identifier:None
interface IERC721{event Transfer(address indexed from,address indexed to,uint256 indexed tokenId);event Approval(address indexed owner,address indexed approved,uint256 indexed tokenId);event ApprovalForAll(address indexed owner,address indexed operator,bool approved);function safeTransferFrom(address from,address to,uint256 tokenId)external;function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data)external;function transferFrom(address from,address to,uint256 tokenId)external;function approve(address to,uint256 tokenId)external;function getApproved(uint256 tokenId)external view returns(address operator);}
interface IERC721Metadata{function name()external pure returns(string memory);function symbol()external pure returns(string memory);function tokenURI(uint256 tokenId)external view returns(string memory);}
interface IOwlWarLand{function MINT(address _t,uint256 _a)external;} 
contract OwlDefenseERC721AC is IERC721,IERC721Metadata{
    struct Player{
        mapping(uint256=>uint256[])item; //0-lumberjack 1-miner 2-farmer 3-factory 4-house 5-barrack 6-tower
        uint256 wood;
        uint256 metal;
        uint256 food;
        uint256 owl;
        uint256 soldier;
        uint256 balance;
        uint256 lastClaimed;
    }
    struct NFT{
        address owner;
        uint256 item;
        uint256 level;
    }
    address private _owner;
    uint256 private _count;
    string[][] private cidURI; //item,level,cid
    mapping(address=>Player)public player;
    mapping(uint256=>NFT)public nft;
    IOwlWarLand private iOWL;
    modifier onlyOwner(){require(_owner==msg.sender);_;}
    constructor(){_owner=msg.sender;}
    function name()external pure override returns(string memory){return"Owl Defense";}
    function symbol()external pure override returns(string memory){return"OD";}
    function tokenURI(uint256 _c)external view override returns(string memory){
        return string(abi.encodePacked("ipfs://",cidURI[nft[_c].item][nft[_c].level]));
    }
    function setURI(uint256 _i,uint256 _l,string memory _c)external onlyOwner{
        cidURI[_i][_l]=_c;
    }
    function safeTransferFrom(address _f,address _t,uint256 _c)external override{
        transferFrom(_f,_t,_c);
    }
    function safeTransferFrom(address _f,address _t,uint256 _c,bytes memory _d)external override{
        require(keccak256(abi.encodePacked(_d))==keccak256(abi.encodePacked(_d)));
        transferFrom(_f,_t,_c);
    }
    function transferFrom(address _f,address _t,uint256 _c)public override{unchecked{
        require(nft[_c].owner==_f);
        nft[_c].owner=_t;
        for(uint256 i=0;i<player[_f].item[nft[_c].item].length;i++){
            if(player[_f].item[nft[_c].item][i]==_c){
                player[_f].item[nft[_c].item][i]=
                player[_f].item[nft[_c].item][player[_f].item[nft[_c].item].length-1];
                player[_f].item[nft[_c].item].pop();
            }
        }
        player[_t].item[nft[_c].item].push(_c);
        player[_f].balance--;
        player[_f].balance++;
        autoMerge(nft[_c].item,nft[_c].level,_t);
        CLAIM(_f);
        CLAIM(_t);
        emit Transfer(_f,_t,_c);
    }}
    function approve(address _t,uint256 _c)external override{
        emit Approval(nft[_c].owner,_t,_c);
    }
    function getApproved(uint256 _c)external view override returns(address){
        require(_c==_c);
        return msg.sender;
    }
    function supportsInterface(bytes4 _t)external pure returns(bool){
        return _t==type(IERC721).interfaceId||_t==type(IERC721Metadata).interfaceId;
    }
    function ownerOf(uint256 _c)external view returns(address){
        return nft[_c].owner;
    }
    function setAddress(address _a)external onlyOwner{
        iOWL=IOwlWarLand(_a);
    }
    function getPlayerItem(address _a,uint256 _i)external view returns(uint256[]memory){
        return player[_a].item[_i];
    }
    function CLAIM(address _a)public{unchecked{
        uint256 _lc=player[_a].lastClaimed;
        uint256 lapsedLoop=(block.timestamp-_lc)/21600; //criteria for new and claimable player, 6 hours
        if(lapsedLoop>0){ 
            if(_lc>0){ //only claim when not a new player
                player[_a].wood+=_getCount(player[_a].item[0],3)*lapsedLoop;
                player[_a].metal+=_getCount(player[_a].item[1],3)*lapsedLoop;
                player[_a].food+=_getCount(player[_a].item[2],3)*lapsedLoop;
                uint256 counts;
                uint256 minTriple=player[_a].wood<=player[_a].metal? //check which one has the least quantity
                    player[_a].wood<=player[_a].food?player[_a].wood:player[_a].food:
                    player[_a].metal<=player[_a].food?player[_a].metal:player[_a].food;
                if(minTriple>2&&player[_a].item[3].length>0){ //have at least 3 resource each and 1 factory
                    counts=_getCount(player[_a].item[3],3)*lapsedLoop/3;
                    minTriple*=lapsedLoop/3; //conversion to owl proportional to the number of factories
                    minTriple=minTriple<=counts?counts:minTriple;
                    player[_a].owl+=minTriple;
                    player[_a].wood-=minTriple*3; //deduct only those converted resources
                    player[_a].metal-=minTriple*3;
                    player[_a].food-=minTriple*3;
                }
                counts=0;
                minTriple=0;
                if(player[_a].owl>2&&player[_a].item[4].length>0){ //have at least 3 owls and 1 house
                    counts=_getCount(player[_a].item[4],3)*lapsedLoop/3;
                    minTriple=player[_a].owl*lapsedLoop/3;
                    minTriple=minTriple<=counts?counts:minTriple;
                    iOWL.MINT(msg.sender,10);
                    player[_a].owl-=minTriple*3;
                }
                player[_a].soldier+=_getCount(player[_a].item[5],1)*lapsedLoop;
            }
            player[_a].lastClaimed=block.timestamp; //reset claimed time
        }
    }}
    function _getCount(uint256[]memory _i,uint256 _m)private view returns(uint256){unchecked{
        uint256 _c;
        for(uint256 i=0;i<_i.length;i++)_c+=_m*3**nft[_i[i]].level*(80+nft[_i[i]].level*20)/100;
        return _c;
    }}
    function MINT(uint256 _i)external payable{unchecked{
        require(msg.value>=0/*.05 DEVELOPMENT UNCOMMENT THIS*/ ether);
        _count++;
        player[msg.sender].item[_i].push(_count);
        player[msg.sender].balance++;
        nft[_count].owner=msg.sender;
        nft[_count].item=_i;
        nft[_count].level=1;
        emit Transfer(address(0),msg.sender,_count);
        autoMerge(_i,1,msg.sender);
        CLAIM(msg.sender);
    }}
    function autoMerge(uint256 _i,uint256 _l,address _a)private{unchecked{
        bool isMerge=true;
        while(isMerge){
            isMerge=false;
            uint256[3] memory levelCount;
            uint256 j=0;
            for(uint256 i=0;i<player[_a].item[_i].length;i++){
                if(nft[player[_a].item[_i][i]].level==_l){
                    if(j<levelCount.length)levelCount[j]=player[_a].item[_i][i];
                    j++;
                    if(j==levelCount.length){
                        for(uint256 k=0;k<levelCount.length;k++){
                            delete nft[levelCount[k]]; //REMIX: can't get back gas fee
                            emit Approval(_a,address(0),levelCount[k]);
                            for(uint256 l=0;l<player[_a].item[_i].length;l++){
                                if(player[_a].item[_i][l]==levelCount[k]){
                                    player[_a].item[_i][l]=player[_a].item[_i][player[_a].item[_i].length-1];
                                    player[_a].item[_i].pop(); //REMIX: can't get back gas fee
                                }
                            }
                            levelCount[k]=0;
                        }
                        _count++;
                        _l++;
                        player[_a].item[_i].push(_count);
                        player[_a].balance-=2; //REMIX: if can't burn this will get error
                        nft[_count].owner=_a;
                        nft[_count].item=_i;
                        nft[_count].level=_l;
                        emit Approval(address(0),_a,_count);
                        isMerge=true;
                    }
                }   
            }
        }
    }}
    function ATTACK(address _a)public{unchecked{
        uint256 _defense=_getCount(player[_a].item[5],2);
        if(player[msg.sender].soldier>0){ //only attack when there is soldier
            if(_defense>=player[msg.sender].soldier)player[msg.sender].soldier=0;
            else{
                player[msg.sender].soldier-=_defense;
                uint256 counts=player[msg.sender].soldier>=player[_a].owl?player[msg.sender].soldier:player[_a].owl;
                player[msg.sender].soldier-=counts;
                player[msg.sender].owl+=counts;
                player[_a].owl-=counts;
                counts=player[msg.sender].soldier>=player[_a].food?player[msg.sender].soldier:player[_a].food;
                if(counts>0){                
                    player[msg.sender].soldier-=counts;
                    player[msg.sender].food+=counts;
                    player[_a].food-=counts;
                    counts=player[msg.sender].soldier>=player[_a].metal?player[msg.sender].soldier:player[_a].metal;
                    if(counts>0){                
                        player[msg.sender].soldier-=counts;
                        player[msg.sender].metal+=counts;
                        player[_a].metal-=counts;
                        counts=player[msg.sender].soldier>=player[_a].wood?player[msg.sender].soldier:player[_a].wood;
                        if(counts>0){                
                            player[msg.sender].soldier-=counts;
                            player[msg.sender].wood+=counts;
                            player[_a].wood-=counts;
                        }
                    }
                }
            }
        }
    }}
}