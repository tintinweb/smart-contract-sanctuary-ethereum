// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "ERC721.sol";
import "ERC721Enumerable.sol";
import "IERC721.sol";
import "IChubbyKaijuDAOCorp.sol";
import "IChubbyKaijuDAOInvasion_legacy.sol";
/***************************************************************************************************
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddddddxxxxxdd
kkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxkxkkkkkkkkkkkkkkkkkkkkkxxddddddddddddxxkkkxx
kkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkxxdddddxxxxxkkkkkkkkkkkkkkkkxxddddddddddddxxkxkk
kkkkkkkkkkkkkkkkkkkkxxxxxddddxxkxxkkxxkkkkkkkxxkkxxkkkxxddddddddxxxxkkkkkkkkxxkkkxxddddddddddddxxkkk
kkkkkkkkkkkkkkkxxxxddddddddxxxxkxxoooodxkkkkkxxdooddxkxxkkkxxxxdddddxxxkkkkkkkkkkkxxdddddddddddddxkk
kkkkkkkkkkkkxxxdddddoddxxxxkkkxl,.',,''.',::;'.''','',lxxxkkkkxxddddddxxxkkkxxxxxkkxddddddddddddddxk
kkkkkkkkxxxdddddddddddxxxxdddo,.,d0XXK0kdl;,:ok0KKK0x;.'lxxxxxxxxddddddddxxkkxxxxxxddodddddddddddddx
kkkkkxxxddddddddddddddddddddl'.:KMMMMMMMMNKXWMMMWWMMWXc..';;;:cloddddddddddxkkxxdddddodddddddddddddd
kkxxxddddddddddddddddddddddc..c0WMMMMMMMMWXNMMMMMMMWk;,',;::;,'..':oxxxxddodxxxkxxdddddxdddddddddddd
kxxdddddddddddddddddddddoc'.'d0XWMMMMMMMMMWMMMMMMMMWXOKNWWMMMWX0kl,.'cdkkxxxddddxdddxxkkkxxxdddddddd
xddddxxxxxxdddddddddddl:'.,xXNKKNMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMNk:..cxkkxxxddddddxkkkkkkkxddddddd
xxxxxkkkxxxdddddddddo;..ckNMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk,.,dxxkkxxxdddxkkkkkxkkxdddddd
kkkkxxxxdddddddoddo:..c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..cxkkkkkxxxxkkkkkkkkkxddddd
kkkxxxddoddddddddd:..xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNXNWWMMMMMMMMMMWNO,.;dkkkkkxkkxxkkkkkkkxxdddd
kxxxdddddo:'',;:c;. lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNWMMMMMWMMMWMMMXc.'okxkkkkkkkkkkkkkkkxdddd
xxdddddodo' .;,',,,:ONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc;;:xXMMMMMMMMMMMWNNNXd..lkkkkkkkkkxkkkkkkkxddd
ddddddddddc..oKKXWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMWkc'      ,0MMMMMMMMMWNNNXNWx..okkkkkkkkkkkkkkkkxdod
dddddddddddl..l0XNNWWWMMWXNMMMMMMMMMMMMMMMMMMMMNd.   ....  :XMMMMMMWWW0l,,;d0l.,xkkkxkkkkkkkkkkkxddd
ddddddddddxko'.,lxO0KXNNO;cXMMMMMMMMMMMMMMMMMMMk.  ....... .kMMMMMMMWk.     :x'.lkkkkkkkkkkkkkkkkxdd
ddddddddxxxkkxl;'.'',:cl:..dWMMMMMMMMMMMMMMMMMWl  ........ .kMMMMMMMNc  ... .c, :xxkkkkkkkkkkkkkkxdd
dddddddxkkkkkkkkxdoc:;,''. ;KMMMMMMMMMMMMMMMMMWl  .......  ,KWWMWX0Ox'       '..cxxkkkkkkkkkkkkkkxdd
dddddxxkkkkkkkkxxkkxkkkkxo'.oWMMMMMMMMMMMMMMMMMO'    ...  .xKkoc;,,,;,.   ,:;,...:dkxkkxkkkkkkkkkxdd
ddddxxkkkkkkkkkkkkkxkkxxddc..kWMMMMMMMMMMMMMMMMMXdc:.. ..;:;...'oOXNWO:colkWMWXk;.,xkxkkkkkkkkkkkxdd
ddxxkkxxkkkkkkkkkkkkxxddddo;.;KMMMMMMMMMMMMMMMMMMMMWX0O0XXxcod;cKMMMMWKl:OMMMMMM0,.lkxkkkkkkkkkkkxdd
dxxkkkkkkkkkkkkxxkkxxddddddo,.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMWMKc:KMMMMMNxoKMMWMMM0,.lkxxxkkkkkkkkxxdd
xxkkkkkkkkkkkkkkkkxxddddddddl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNWMWMMMMWWMMMWMMNl.,dkkkxkkkkkkkkxddd
xkkkkkkkkkkkkkkkkxdddddddddodl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMKdOWNxo0WNxlOWKcoXNo..okxxkkkkkkkkkkxddd
kkkkkkkkkkkkkkkkkxddodddddddddo'.,OWMMMMMMMMMMMMMMMMMMMMMN0Oc .lc. .l:. .;. .,, .lkxxkkkkkkkkkkxxddd
kkkkkkkkkkkkkkkkxddddddddddddddo' cNMMMMMMMMMMMMMMMMMMMMMKl,;'. .,,. .'. .,. '' 'xkkxkkkkkkkkkkxdddd
kkkkkkkkkkkkkkkkxddoddddl:,'..';. :NMMMMMMMMMMMMMMMMMMMMMWWWWKlc0WNd,xNx;kWx;xl ,xkkkkxxkkxxkkxxdddd
kkkkkkkkkkkkkkkkxdddddo:..:dxdl'  ,0MMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMWWWMWWMMWWK; :kkkkkkkkkkxkkxddddd
kkkkkkkkkxkkkkkxxdoddo; 'kNMWMNl.'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMK:.'dkkkkkxkkkkkkxdddddd
kkkkkkkkkkkxkkkxxddddo' lXNMMWo.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o' 'dkkkkxxkkkkkkxxdddddd
kkkkkkkxkkkkkkkxdc;,,'.,kXNMMWK0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXO:,,..ckkkkxkkkxkkxxddddddd
kkkkkkkkkxxkxkxc..;loox0KKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNNXXXXXXXXXXXKXXk'.cxkxkkxkkkxxdddddddd
kkkkkkkkkkkkxkl..xNMMMMWNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNWWWWWMMMMMMWO'.ckxkkxkxxxdoddddddx
kkkkkkkkkkkkkx, cNMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..okkkkxddddddddddxx
kkkkkkkkkkkkkx, cNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.'dkxxddddddddddxkk
kkkkkkkkkxkxxx: ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMMMMMMMMMMMX; :ddddddddoddxxkkx
kkkkkkkkxxkkxko..dNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNXXXXXXXNNWMMMMMMMMMWk..cdddddddddxxkxxd
kkkkkkkxxkkxkkx, cXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMWWWNNNNWMMMMMMMMN: ,oddddddxxxkxxdd
kkkkkkkkkkkxkko..oXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNWMMMMMMMMMMMMMMMMWWWMMMMMMMMWk..ldddddxkkxkkxxx
xkkkkkkkkkkxkd,.lXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; ;dddxxkkkkxxkkk
xxkkkkkkkxkkk: :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo 'dxxkkkkkkkkkkk
dxkkkkkkkkxkx, dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO..okxkkkkkkkkkkx
ddxkkxkkkkxkd'.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMX; ckkkkkkkkkkxxd
dodxxkkkkxkkx; cWMMMMWNWMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMWc ;xkkkxkkkxxddd
dddddxxkkkkxkl..OWMMWNXWMMMMMMMMMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMMMd.'dkkkkxxdddddd
ddddddxxkkkkkx; :KWWN0KWMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMk..okxxxdddddddd
ddddddddxxkkkkl..xXX0ccKMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMM0'.lxddddddddddd
***************************************************************************************************/

contract ChubbyKaijuDAOInvasion_new is ERC721Enumerable, Ownable{
    using Address for address;
    using Strings for uint256;

    mapping(address => bool) public controllers;


    bool private ispublicSale;
    bool private isMutate;

    uint256 public migrated=2479;
    uint256 public zombieMinted=2479*2;
    uint256 public alienMinted;
    uint256 public superalienMinted;
    uint256 public undeadMinted;
    uint256 public superundeadMinted;
    //uint256 superMinted;

    uint256 public constant ALIEN_BASE = 6666;
    uint256 public constant UNDEAD_BASE = 9999;
    uint256 public constant SUPER_BASE = 20000;

    string private baseURI; 
    address private signer;
    
    uint256 public PUBLIC_MINT_PRICE = 0.04 ether;

    uint16 public round_gen2;

    address[] public alien_leaders;
    address[] public zombie_leaders;
    address[] public undead_leaders;

    mapping(uint256 => uint16) public traits; // 0 for zombie, 1 for alien, 2 for undead, 10 for burned zombie

    IChubbyKaijuDAOCorp private chubbykaijudaocorp;
    IChubbyKaijuDAOInvasion_legacy private kaiju_legacy;

    constructor() ERC721("ChubbyKaijuDAOInvasion", "CKAIJU2"){
        
    }

    function initialize(address _corpAddress, address _legacyAddress) public onlyOwner {
        chubbykaijudaocorp = IChubbyKaijuDAOCorp(_corpAddress);
        kaiju_legacy = IChubbyKaijuDAOInvasion_legacy(_legacyAddress);
    }

    function manualMigration(address[] memory addresses, uint16[] memory tokenIds) external {
        require(controllers[msg.sender], "Only controllers can do this");
        require(addresses.length == tokenIds.length, "Must have same length");
        for(uint i=0;i<tokenIds.length;i++){
            if(tokenIds[i] < 6667 && !_exists(tokenIds[i])){
                traits[tokenIds[i]]=0;
                _mint(addresses[i], tokenIds[i]);

                migrated++;
                traits[migrated]=0;
                _mint(addresses[i], migrated);
            }
        }

    }

    function hasMigrated(uint256 tokenId) public view  returns (bool){
        return _exists(tokenId);
    }

    function migration() external {
        require(kaiju_legacy.balanceOf(msg.sender)>0,"Must Have Zombie");
        uint16[] memory tokens = kaiju_legacy.tokensOf(msg.sender);
        for(uint i=0; i<tokens.length;i++){
            if(tokens[i] < 6667 && !_exists(tokens[i])){
                traits[tokens[i]] = 0;
                _mint(msg.sender, tokens[i]);
                migrated++;
                traits[migrated] = 0;
                _mint(msg.sender, migrated);
            }
        }
    }

    function publicSale(uint16 amount) external payable {
        require(ispublicSale, "Not Publicsale Preiod");
        require(zombieMinted+amount<6667,"All zombies are minted");
        require(msg.value >= amount*PUBLIC_MINT_PRICE, "Not Enough ETH");
        for(uint i=0; i<amount; i++){
            zombieMinted++;
            traits[zombieMinted]=0;
            _mint(msg.sender, zombieMinted);
        }
    }

    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        return super.ownerOf(tokenId);
    }

    function tokensOf(address owner) external view returns (uint16[] memory) {
        uint32 tokenCount = uint32(balanceOf(owner));
        uint16[] memory tokensId = new uint16[](tokenCount);
        for (uint32 i = 0; i < tokenCount; i++){
            tokensId[i] = uint16(tokenOfOwnerByIndex(owner, i));
        }
        return tokensId;
    }    

    function contractURI() public view returns (string memory) {
        //TODO change contractURI
        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), "contracturi")) : "";
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "nonexistent token");
        return bytes(_baseURI()).length > 0 ? string(abi.encodePacked(_baseURI(), tokenId.toString())) : "";
    }

    function _baseURI() internal view override returns (string memory) {
        //TODO change baseURI
        return baseURI;
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    function setLeadersGen2(address alien, address zombie, address undead) external onlyOwner {
        alien_leaders.push(alien);
        zombie_leaders.push(zombie);
        undead_leaders.push(undead);
        round_gen2++;
    }

    function setPublic(bool ispublic) external onlyOwner {
        ispublicSale = ispublic;
    }
    function setMutate(bool mutate) external onlyOwner{
        isMutate=mutate;
    }
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
    }

    function setPrice(uint256 price) external onlyOwner {
        PUBLIC_MINT_PRICE = price;
    }

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function withdraw() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }
}