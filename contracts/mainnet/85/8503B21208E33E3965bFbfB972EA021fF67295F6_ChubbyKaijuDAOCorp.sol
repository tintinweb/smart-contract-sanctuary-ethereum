// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Strings.sol";
import "./Ownable.sol";
import "./IChubbyKaijuDAOCrunch.sol";
import "./IChubbyKaijuDAOInvasion.sol";

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



contract ChubbyKaijuDAOCorp is ERC1155, Ownable {
    using Strings for uint256;

    address private signer_wl;
    address private signer_free;
    uint128 public constant RADIO_CRUNCH_PRICE = 75 ether;
    uint128 public constant SERUM_CRUNCH_PRICE = 125 ether;

    uint128 public constant RADIO_ETH_PRICE = 0.065 ether;
    uint128 public constant SERUM_ETH_PRICE = 0.085 ether;

    uint16 public constant TYPE_RADIO = 0;
    uint16 public constant TYPE_SERUM = 1;
    uint16 public constant TYPE_SUPER_RADIO = 2;
    uint16 public constant TYPE_SUPER_SERUM = 3;

    uint16 public constant MAX_RADIO = 3328;
    uint16 public constant MAX_SERUM = 3328;

    uint16 public freeRadioRemained = 748;
    uint256 public radioMinted;
    uint256 public serumMinted;

    mapping(address => bool) public freePurchased;
    mapping(address => mapping(uint256=>bool)) public isPurchased1;
    mapping(address => mapping(uint256=>uint256)) public isPurchased2;
    mapping(address => mapping(uint256=>uint256)) public isPurchased3;
    mapping(address => mapping(uint256=>uint256)) public isPurchased4;

    bool private ispreSale1;
    bool private ispreSale2;
    bool private ispreSale3;
    bool private ispublicSale;

    bool private isCrunch;
    
    address private invasionContract;
    string private baseURI;


    mapping(uint256 => bool) public validTypes;

    event SetBaseURI(string indexed _baseURI);

    IChubbyKaijuDAOCrunch private chubbykaijuDAOCrunch;
    IChubbyKaijuDAOInvasion private chubbykaijuDAOInvasion;

    constructor(address crunch, string memory _baseURI) ERC1155(_baseURI) {
        chubbykaijuDAOCrunch = IChubbyKaijuDAOCrunch(crunch);
        chubbykaijuDAOCrunch.approve(address(this), 1000000000000000000000000000000);
        baseURI = _baseURI;
        validTypes[0] = true;
        validTypes[1] = true;
        validTypes[2] = true;
        validTypes[3] = true;   
        emit SetBaseURI(baseURI);
    }

    function mintBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        onlyOwner
    {
        _mintBatch(owner(), ids, amounts, "");
    }

    function freeRadio(bytes memory signature) external {
        require(signerCheck(msg.sender, signature) == signer_free,"Not Free radio minter");
        require(!freePurchased[msg.sender], "Already Minted");
        require(chubbykaijuDAOInvasion.balanceOf(msg.sender)>0, "Must Own Zombie");
        require(radioMinted+1<MAX_RADIO+1,"All radios are minted");
        _mint(msg.sender, TYPE_RADIO, 1, "");
        freePurchased[msg.sender]=true;
        radioMinted++;
        freeRadioRemained--;
    }

    function preSale(bytes memory signature, uint256 id, uint256 amount) external payable {
        require(ispreSale1 || ispreSale2 || ispreSale3, "Not Presale Period");
        require(validTypes[id], "Not Valid Typeid");
        require(id!=TYPE_SUPER_RADIO && id!=TYPE_SUPER_SERUM, "Only Owner Can Mint SUPER TYPE");
        require(signerCheck(msg.sender, signature) == signer_wl,"Not Whitelisted");
        require(chubbykaijuDAOInvasion.balanceOf(msg.sender)>0, "Must Own Zombie");
        if(ispreSale1){
            require(!isPurchased1[msg.sender][id], "Already Minted All");
            require(amount==1, "No more than one");
            if(id==TYPE_RADIO){
                require(radioMinted+amount<MAX_RADIO+1-freeRadioRemained,"All radios are minted");
                require(RADIO_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.balanceOf(msg.sender), "not enough balance");
                require(RADIO_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.allowance(msg.sender, address(this)), "low allowance");
                chubbykaijuDAOCrunch.burn(msg.sender, RADIO_CRUNCH_PRICE * amount);
                radioMinted = radioMinted+amount;
            }else{
                require(serumMinted+amount<MAX_SERUM+1,"All serums are minted");
                require(SERUM_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.balanceOf(msg.sender), "not enough balance");
                require(SERUM_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.allowance(msg.sender, address(this)), "low allowance");
                chubbykaijuDAOCrunch.burn(msg.sender, SERUM_CRUNCH_PRICE * amount);
                serumMinted = serumMinted+amount;
            }
            _mint(msg.sender, id, amount, "");
            isPurchased1[msg.sender][id] = true;
        }else if(ispreSale2){
            require(isPurchased2[msg.sender][id] + amount < 11, "Already Minted All");
            if(id==TYPE_RADIO){
                require(radioMinted+amount<MAX_RADIO+1-freeRadioRemained,"All radios are minted");
                require(RADIO_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.balanceOf(msg.sender), "not enough balance");
                require(RADIO_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.allowance(msg.sender, address(this)), "low allowance");
                chubbykaijuDAOCrunch.burn(msg.sender, RADIO_CRUNCH_PRICE * amount);
                radioMinted = radioMinted+amount;
            }else{
                require(serumMinted+amount<MAX_SERUM+1,"All serums are minted");
                require(SERUM_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.balanceOf(msg.sender), "not enough balance");
                require(SERUM_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.allowance(msg.sender, address(this)), "low allowance");
                chubbykaijuDAOCrunch.burn(msg.sender, SERUM_CRUNCH_PRICE * amount);
                serumMinted = serumMinted+amount;
            }
            _mint(msg.sender, id, amount, "");
            isPurchased2[msg.sender][id] = isPurchased2[msg.sender][id]+amount;
        }else{
            require(isPurchased3[msg.sender][id] + amount < 11, "Already Minted All");
            if(id==TYPE_RADIO){
                require(radioMinted+amount<MAX_RADIO+1-freeRadioRemained,"All radios are minted");
                if(isCrunch){
                    require(RADIO_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.balanceOf(msg.sender), "not enough balance");
                    require(RADIO_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.allowance(msg.sender, address(this)), "low allowance");
                    chubbykaijuDAOCrunch.burn(msg.sender, RADIO_CRUNCH_PRICE * amount);
                }else{
                    require(msg.value >= amount*RADIO_ETH_PRICE, "Not Enough ETH");
                }
                radioMinted = radioMinted+amount;
            }else{
                require(serumMinted+amount<MAX_SERUM+1,"All serums are minted");
                if(isCrunch){
                    require(SERUM_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.balanceOf(msg.sender), "not enough balance");
                    require(SERUM_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.allowance(msg.sender, address(this)), "low allowance");
                    chubbykaijuDAOCrunch.burn(msg.sender, SERUM_CRUNCH_PRICE * amount);
                }else{
                    require(msg.value >= amount*SERUM_ETH_PRICE, "Not Enough ETH");
                }
                
                serumMinted = serumMinted+amount;
            }


            _mint(msg.sender, id, amount, "");
            isPurchased3[msg.sender][id] = isPurchased3[msg.sender][id]+amount;
        }
        
    }


    function publicSale(uint256 id, uint256 amount) external payable {
        require(ispublicSale, "Not Publicsale Preiod");
        require(validTypes[id], "Not Valid Typeid");
        require(id!=TYPE_SUPER_RADIO && id!=TYPE_SUPER_SERUM, "Only Owner Can Mint SUPER TYPE");
        require(isPurchased4[msg.sender][id] + amount < 11, "Already Minted All");
        require(chubbykaijuDAOInvasion.balanceOf(msg.sender)>0, "Must Own Zombie");
        if(id==TYPE_RADIO){
            require(radioMinted+amount<MAX_RADIO+1-freeRadioRemained,"All radios are minted");
            if(isCrunch){
                require(RADIO_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.balanceOf(msg.sender), "not enough balance");
                require(RADIO_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.allowance(msg.sender, address(this)), "low allowance");
                chubbykaijuDAOCrunch.burn(msg.sender, RADIO_CRUNCH_PRICE * amount);
            }else{
                require(msg.value >= amount*RADIO_ETH_PRICE, "Not Enough ETH");
            }
            radioMinted = radioMinted+amount;
        }else{
            require(serumMinted+amount<MAX_SERUM+1,"All serums are minted");
            if(isCrunch){
                require(SERUM_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.balanceOf(msg.sender), "not enough balance");
                require(SERUM_CRUNCH_PRICE * amount <= chubbykaijuDAOCrunch.allowance(msg.sender, address(this)), "low allowance");
                chubbykaijuDAOCrunch.burn(msg.sender, SERUM_CRUNCH_PRICE * amount);
            }else{
                require(msg.value >= amount*SERUM_ETH_PRICE, "Not Enough ETH");
            }
            serumMinted = serumMinted+amount;
        }

        _mint(msg.sender, id, amount, "");
        isPurchased4[msg.sender][id] = isPurchased4[msg.sender][id]+amount;
    }

    function burnCorpForAddress(uint256 typeId, address burnTokenAddress)
        external
    {
        require(msg.sender == invasionContract, "Invalid burner address");
        _burn(burnTokenAddress, typeId, 1);
    }

    function updateBaseUri(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
        emit SetBaseURI(baseURI);
    }

    function uri(uint256 typeId)
        public
        view                
        override
        returns (string memory)
    {
        require(
            validTypes[typeId],
            "URI requested for invalid serum type"
        );
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, typeId.toString()))
                : baseURI;
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
        keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
        );
    }

    function signerCheck(address user, bytes memory signature) public view returns (address) {
        bytes32 messageHash = keccak256(abi.encode(user));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) private pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "sig invalid");

        assembly {
        /*
        First 32 bytes stores the length of the signature

        add(sig, 32) = pointer of sig + 32
        effectively, skips first 32 bytes of signature

        mload(p) loads next 32 bytes starting at the memory address p into memory
        */

        // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
        // second 32 bytes
            s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
    function setCrunchContract(address _address) external onlyOwner {
        chubbykaijuDAOCrunch = IChubbyKaijuDAOCrunch(_address);
    }

    function setInvasionContract(address _address) external onlyOwner{
        chubbykaijuDAOInvasion = IChubbyKaijuDAOInvasion(_address);
        invasionContract = _address;
    }

    function setSale(uint16 step) external onlyOwner {
        if(step==1){
            ispreSale1=true;
            ispreSale2=false;
            ispreSale3=false;
            ispublicSale=false;
        }else if(step==2){
            ispreSale1=false;
            ispreSale2=true;
            ispreSale3=false;
            ispublicSale=false;
        }else if(step==3){
            ispreSale1=false;
            ispreSale2=false;
            ispreSale3=true;
            ispublicSale=false;
        }else if(step==4){
            ispreSale1=false;
            ispreSale2=false;
            ispreSale3=false;
            ispublicSale=true;
        }else{
            ispreSale1=false;
            ispreSale2=false;
            ispreSale3=false;
            ispublicSale=false;
        }
    }

    function setSigners(address freeMint, address wl) external onlyOwner{
        signer_free = freeMint;
        signer_wl = wl;
    }

    function setCrunch(bool crunch) external onlyOwner{
        isCrunch = crunch;
    }

    function withdrawETH() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }
    function withdrawCRUNCH() public onlyOwner{
        chubbykaijuDAOCrunch.transferFrom(address(this), owner(), chubbykaijuDAOCrunch.balanceOf(address(this)));
    }
}