// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
/**
 * @title JiggleOs-On-Chain contract
 * @author Jiggle Labs
 * @dev Extends ERC721 Non-Fungible Token Standard basic implementation
 * @notice Generate 4294967295 free JiggleOs with the option to mint 10000
 * @notice This project is self-contained inside this non-upgradeable, one-page contract
 *
 *         gg                                                     _,gggggg,_
 *        dP8,                                   ,dPYb,         ,d8P""d8P"Y8b,
 *       dP Yb                                   IP'`Yb        ,d8'   Y8   "8b,dP
 *      ,8  `8,     gg                           I8  8I        d8'    `Ybaaad88P'
 *      I8   Yb     ""                           I8  8'        8P       `""""Y8
 *      `8b, `8,    gg     ,gggg,gg    ,gggg,gg  I8 dP   ,ggg, 8b            d8  ,g,
 *       `"Y88888   88    dP"  "Y8I   dP"  "Y8I  I8dP   i8" "8iY8,          ,8P ,8'8,
 *           "Y8    88   i8'    ,8I  i8'    ,8I  I8P    I8, ,8I`Y8,        ,8P',8'  Yb
 *            ,88,_,88,_,d8,   ,d8I ,d8,   ,d8I ,d8b,_  `YbadP' `Y8b,,__,,d8P',8'_   8)
 *        ,ad888888P""Y8P"Y8888P"888P"Y8888P"8888P'"Y88888P"Y888  `"Y8888P"'  P' "YY8P8P
 *      ,dP"'   Yb             ,d8I'       ,d8I'
 *     ,8'      I8           ,dP'8I      ,dP'8I   Jiggleos-On-Chain is a collection of 10,000
 *    ,8'       I8          ,8"  8I     ,8"  8I   unique animations created by the minters out
 *    I8,      ,8'          I8   8I     I8   8I   of a possible 4,294,967,295. It's a very long,
 *    `Y8,___,d8'           `8, ,8I     `8, ,8I   if not the longest animated film ever made.
 *      "Y888P"              `Y8P"       `Y8P".
 */
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {} lt(dataPtr, endPtr) {}{
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        return result;
    }
}

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

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
    unchecked {
        counter._value += 1;
    }
    }
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

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

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
contract JiggleosOnChain is ERC721, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;
    using Strings for uint256;
    bool public saleON = false;
    string public base_external_url;
    string public base_img_url;
    string public youtube_url;
    string public img_suffix;
    string internal constant head = '<svg id="JSVG" viewBox="0 0 1000 1000" version="1.1" xmlns="http://www.w3.org/2000/svg"> \n <title>JiggleOs-On-Chain - Generative Ethereum Animation</title> \n <script>//<![CDATA[\n document.addEventListener("DOMContentLoaded",function(){ class R{constructor(S){this.S=S;}r_d(){this.S^=this.S<<13;this.S^=this.S>>17;this.S^=this.S<<5;return((this.S<0?~this.S+1:this.S)%1000)/1000;}r_b(a,b){return a+(b-a)*this.r_d();}r_i(a,b){return Math.floor(this.r_b(a,b+1));}r_c(x){return x[Math.floor(this.r_b(0,x.length*0.99))];}};const S=';
    string internal constant tail = ';const r=new R(S);const ns="http://www.w3.org/2000/svg";const dX=r.r_i(-5,5);const dY=r.r_i(-5,5);const rF=r.r_b(1,5);const cF=r.r_b(5,15);const ra=r.r_c([30,60,90,120,150.180]);let s=1000;let l=r.r_b(1,360);let lR=(l+180)%360;const bg=document.createElementNS(ns,"rect");bg.setAttribute("width",s);bg.setAttribute("height",s);bg.setAttribute("fill","hsl("+lR+",100%,50%)");document.getElementById("JSVG").appendChild(bg);let rt=[];for(let i=0;i<200;i++){ let mR=document.createElementNS(ns,"rect");mR.setAttribute("x",r.r_b(0,s));mR.setAttribute("y",r.r_b(0,s));mR.setAttribute("width",r.r_b(1,s/rF));mR.setAttribute("height",r.r_b(1,s/rF));mR.setAttribute("fill","hsl("+((r.r_b(0,1)*(lR+ra-(lR-ra)))+(lR-ra))+","+((r.r_b(70,100)))+"%"+","+((r.r_b(50,80)))+"%");mR.setAttribute("fill-opacity",(r.r_b(.8,1)));mR.setAttributeNS(null,"clip-path","url(#clip)");document.getElementById("JSVG").appendChild(mR);rt.push(mR);};let cr=[];for(let i=0;i<200;i++){ let mC=document.createElementNS(ns,"circle");mC.setAttribute("cx",r.r_b(1,1000));mC.setAttribute("cy",r.r_b(1,1000));mC.setAttribute("r",r.r_b(2,cF));mC.setAttribute("fill","hsl("+((r.r_b(0,1)*(l+ra-(l-ra)))+(l-ra))+","+((r.r_b(80,100)))+"%"+","+((r.r_b(50,100)))+"%");mC.setAttribute("fill-opacity",(r.r_b(.8,1)));mC.setAttributeNS(null,"clip-path","url(#clip)");document.getElementById("JSVG").appendChild(mC);cr.push(mC);};let clippath=document.createElementNS(ns,"clipPath");clippath.setAttributeNS(null,"id","clip");document.getElementById("JSVG").appendChild(clippath);let rect=document.createElementNS(ns,"rect");rect.setAttributeNS(null,"x","0");rect.setAttributeNS(null,"y","0");rect.setAttributeNS(null,"width","1000");rect.setAttributeNS(null,"height","1000");clippath.appendChild(rect);function jR(){ for(let i=0;i<rt.length;i++){let mR=rt[i];let x=parseInt(mR.getAttribute("x"));let y=parseInt(mR.getAttribute("y"));if(x<-mR.getAttribute("width")){x=1000;}else if(x>1000){x=-mR.getAttribute("width");}if(y<-mR.getAttribute("height")){y=1000;}else if(y>1000){y=-mR.getAttribute("height");}mR.setAttribute("x",x+(r.r_b(0,2))*dX);mR.setAttribute("y",y+(r.r_b(0,2))*dY);}}function jC(){ for(let i=0;i<cr.length;i++){let mC=cr[i];let x=parseInt(mC.getAttribute("cx"));let y=parseInt(mC.getAttribute("cy"));if(x<-mC.getAttribute("width")*3){x=1000;}else if(x>1000){x=-mC.getAttribute("width");}if(y<-mC.getAttribute("height")*2){y=1000;}else if(y>1000){y=-mC.getAttribute("height");}mC.setAttribute("cx",x+(r.r_b(0,2))*dX);mC.setAttribute("cy",y+(r.r_b(0,2))*dY);}}setInterval(jR,r.r_i(25, 75));setInterval(jC,r.r_i(25, 75));}); \n //]]> \n </script> \n </svg>';
    string internal constant logo = '<svg viewBox="0 0 1000 1000" version="1.1" xmlns="http://www.w3.org/2000/svg"><title>JiggleOs-On-Chain Logo</title><path fill="#6c9" d="M0 0h1000v1000H0z"/><path fill="#fff" d="M677 76c-7 0-137 31-193 81-1 1-363 344-396 435-86 237 208 436 398 274 127-108 258-238 380-361 136-159 41-429-189-429z"/><path d="M427 324c0 340 514 333 505 0-5-332-505-332-505-1zm318 55c9 144-201 78-168 51 22-15 121 28 118-51 2-194-3-220 25-220 29 0 25 18 25 220z"/></svg>';

    mapping (uint => uint) public idToSeed;
    mapping (uint => uint) public seedToId;
    mapping (uint => string) public idToName;
    mapping (uint => address) public idToSeeder;

    constructor() ERC721("JiggleOs-On-Chain", "JOC") {
        _nextTokenId.increment();
        //@dev alternate url: jiggleos.crypto
        base_external_url = "https://jiggleos.com/";
        base_img_url = "https://jiggleos.com/";
        img_suffix = ".gif";
        youtube_url = "https://www.youtube.com/channel/UCEGGbojYdDQOKk6dUQQeH2A";
    }

    //@notice This function mints 10000 unique JiggleOs for 0.1 ether each
    //@notice The seed number must be unique, between 1 and 4294967295
    //@notice The name can be anything between 1 and 32 characters
    //@notice Once minted, the seed and name are unchangeable. Choose wisely
    //@notice The minter, the one who provides the seed and name, is the director

    function mint(uint32 seed, string memory name) external payable nonReentrant {
        uint id = _nextTokenId.current();

        require(nameLength(name) == true, "Name must be between 1-32 characters");
        require(id < 10001, "Sold out");
        require(seedToId[seed] == 0, "Seed already minted");

        if (msg.sender != owner()) {
            require(saleON, "Sale OFF");
            require(msg.value == 0.1 ether);
        }

        idToName[id] = name;
        idToSeeder[id] = msg.sender;
        idToSeed[id] = seed;
        seedToId[seed] = id;

        _nextTokenId.increment();
        _mint(msg.sender, id);
    }

    function drawSVG(uint256 _tokenId) internal view returns(string memory) {
        uint256 currentSeed = (idToSeed[_tokenId]);
        return Base64.encode(bytes(
                abi.encodePacked(
                    head,
                    currentSeed.toString(),
                    tail
                )));
    }

    function drawLOGO() internal pure returns(string memory) {
        return Base64.encode(bytes(
                abi.encodePacked(
                    logo
                )));
    }

    //@notice This function generates 4 billion unique free JiggleOs!
    //@notice The seed number must be unique between 1 and 4294967295
    //@notice The seed must not be one that has already been minted
    function drawFreeSVG(uint32 _seed) public view returns(string memory) {
        require(seedToId[_seed] == 0, "Seed already minted");
        uint256 currentSeed = _seed;
        return string(abi.encodePacked(
                'data:image/svg+xml;base64,', Base64.encode(bytes(abi.encodePacked(
                    head,
                    currentSeed.toString(),
                    tail
                )))));
    }

    //@notice Both "image_data" and "animation_url" return immutable and lossless original art
    //@notice The "image" returns a fallback raster preview of the original art for compatibility
  function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
      require(_exists(_tokenId),"Nonexistent token");
        string memory director = Strings.toHexString(uint256(uint160(idToSeeder[_tokenId])), 20);
        string memory seed = (idToSeed[_tokenId]).toString();
        return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                    '{"name":"', idToName[_tokenId],
                    '", "description":"', 'JiggleO #', _tokenId.toString(),
                    '", "attributes": [{"trait_type": "Director", "value": "', director,
                    '"},{"trait_type": "Seed", "value": "', seed,
                    '"}], "external_url":"', base_external_url, _tokenId.toString(),
                    '", "image":"', base_img_url, _tokenId.toString(), img_suffix,
                    '", "image_data": "', 'data:image/svg+xml;base64,', drawSVG(_tokenId),
                    '", "animation_url": "','data:image/svg+xml;base64,', drawSVG(_tokenId),
                    '", "youtube_url":"', youtube_url,
                    '"}'
                    )))));
    }

    function contractURI() external view returns(string memory) {
        string memory beneficiary = Strings.toHexString(uint256(uint160(owner())), 20);
        return string(abi.encodePacked(
                'data:application/json;base64,', Base64.encode(bytes(abi.encodePacked(
                    '{"name":"', 'Jiggleos-On-Chain',
                    '", "description":"', 'Jiggleos-On-Chain - 10,000 Generative Ethereum Animations',
                    '",  "external_url":"', base_external_url,
                    '", "image": "', 'data:image/svg+xml;base64,', drawLOGO(),
                    '", "seller_fee_basis_points": "', '250',
                    '", "fee_recipient": "', beneficiary,
                    '"}'
                    )))));
    }

    function totalSupply() external view returns (uint256) {
        return _nextTokenId.current() - 1;
    }

    function remainingSupply() external view returns (uint256) {
        return 10000 - _nextTokenId.current() + 1;
    }

    function nameLength(string memory str) internal pure returns (bool){
        bytes memory b = bytes(str);
        if(b.length < 1) return false;
        if(b.length > 32) return false;
        return true;
    }

    function toggleSale() external onlyOwner {
        saleON = !saleON;
    }

    function setBaseExternalURL(string memory url) external onlyOwner {
        base_external_url = url;
    }

    function setBaseImgURL(string memory url) external onlyOwner {
        base_img_url = url;
    }

    function setYoutubeURL(string memory url) external onlyOwner {
        youtube_url = url;
    }

    function setImgSuffix(string memory suffix) external onlyOwner {
        img_suffix = suffix;
    }

    function withdraw() external payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }
}