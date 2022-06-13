// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IFactoryERC721.sol";
import "./Stellar.sol";

contract StellarFactory is FactoryERC721, Ownable {
    using Strings for string;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event AddOptionEvent(
        uint256 indexed optionId,
        uint32  indexed optionType,
        uint256 mass,
        uint256 appear
    );

    address public proxyRegistryAddress;
    address public nftAddress;
    string public baseURI = "http://43.130.64.52:8888/Stellar/";



    /*
     * Three different options for minting Stellars
     */
    uint32 constant OPTION_TYPE_FIX_APPEAR = 0;
    uint32 constant OPTION_TYPE_RANDOM_APPEAR = 1;
    uint32 constant OPTION_TYPE_MAX_NUM = OPTION_TYPE_RANDOM_APPEAR;
    struct OptionParam{
        uint32  op_type;
        uint256 mass;
        uint256 appear;
        bool isVaild;
    }
    uint256 NUM_OPTIONS = 0;
    mapping (uint256 => OptionParam) mapOptions;

    constructor(address _proxyRegistryAddress, address _nftAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        nftAddress = _nftAddress;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_FIX_APPEAR, 100, 0x000000246e000000000000000000000000048020a4, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_FIX_APPEAR, 100, 0x000024906500000000000000000000000006662461, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_FIX_APPEAR, 103, 0x0000161caa00000000000000000000000002873401, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_FIX_APPEAR, 110, 0x0006370ca900000000000000000000000004743c07, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_FIX_APPEAR, 110, 0x0008f83c4b00000000000000000000000000c53482, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_FIX_APPEAR, 111, 0x0008f02c4f0000000000000000000000000aa18480, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 1, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 4, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 16, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 32, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 64, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 128, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 256, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 512, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 1024, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 2048, 0, true);
        ++NUM_OPTIONS;
        mapOptions[NUM_OPTIONS] = OptionParam(OPTION_TYPE_RANDOM_APPEAR, 4096, 0, true);
        ++NUM_OPTIONS;

        fireTransferEvents(address(0), owner());
    }

    function name() override external pure returns (string memory) {
        return "Stellar Item Sale";
    }

    function symbol() override external pure returns (string memory) {
        return "sis";
    }

    function supportsFactoryInterface() override public pure returns (bool) {
        return true;
    }

    function numOptions() override public view returns (uint256) {
        return NUM_OPTIONS;
    }

    function _addOption(uint32 op_type, uint256 mass, uint256 appear) internal {
        require(op_type <= OPTION_TYPE_MAX_NUM, "op_type Invalid!");
        if(op_type == OPTION_TYPE_RANDOM_APPEAR) {
            appear = 0;
        }
        mapOptions[NUM_OPTIONS] = OptionParam(op_type, mass, appear, true);
        emit AddOptionEvent(NUM_OPTIONS, op_type, mass, appear);
        ++NUM_OPTIONS;
    }

    function addOption(uint32 op_type, uint256 mass, uint256 appear) external onlyOwner {
        _addOption(op_type, mass, appear);
    }

    function addOption(uint256[] memory values) external onlyOwner {
        // values is [type, mass, appear, ……]
        for (uint256 i = 0; i+2 < values.length; i+=3) {
            _addOption(uint32(values[i]), values[i+1], values[i+2]);
        }
    }

    function transferOwnership(address newOwner) override public onlyOwner {
        address _prevOwner = owner();
        super.transferOwnership(newOwner);
        fireTransferEvents(_prevOwner, newOwner);
    }

    function fireTransferEvents(address _from, address _to) private {
        for (uint256 i = 0; i < NUM_OPTIONS; i++) {
            emit Transfer(_from, _to, i);
        }
    }

    function mint(uint256 _optionId, address _toAddress) override public {
        // Must be sent from the owner proxy or owner.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        require(owner() == _msgSender() ||
            address(proxyRegistry.proxies(owner())) == _msgSender() 
            , "sender is not owner");
        require(canMint(_optionId), "optionId can not mint!");

        Stellar _stellar = Stellar(nftAddress);
        OptionParam memory param = mapOptions[_optionId];
        if (param.op_type == OPTION_TYPE_FIX_APPEAR) {
            uint256[] memory arrValue = new uint256[](2);
            arrValue[0] = param.mass;
            arrValue[1] = param.appear;
            _stellar.mintToByFact2(_toAddress, arrValue);
        } else if (param.op_type == OPTION_TYPE_RANDOM_APPEAR) {
            _stellar.mintToByFact(_toAddress, param.mass);
        } else {
            // new type?
        }
    }

    function canMint(uint256 _optionId) override public view returns (bool) {
        if (_optionId >= NUM_OPTIONS) {
            return false;
        }

        return mapOptions[_optionId].isVaild;
    }

    function tokenURI(uint256 _optionId) external view override returns (string memory) {
        require(mapOptions[_optionId].isVaild, "operator query for nonexistent option");
        
        OptionParam memory param = mapOptions[_optionId];
        bytes memory byteString;
        byteString = abi.encodePacked(byteString, baseURI, "getSaleInfo.php?token=", Strings.toString(_optionId));
        byteString = abi.encodePacked(byteString, "&type=", Strings.toString(param.op_type));
        byteString = abi.encodePacked(byteString, "&mass=", Strings.toString(param.mass));
        if(param.op_type == OPTION_TYPE_FIX_APPEAR) {
            Stellar _stellar = Stellar(nftAddress);
            byteString = abi.encodePacked(byteString, "&appear=", _stellar.getSpHexAppearance(param.appear));
        }
        return string(byteString);
    }

    function contractURI() external view returns (string memory) {
        bytes memory byteString;
        byteString = abi.encodePacked(byteString, baseURI, "openseaSaleInfo.php");
        return string(byteString);
    }

    function setBaseURI(string memory strBaseURI) external onlyOwner {
        baseURI = strBaseURI;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use transferFrom so the frontend doesn't have to worry about different method names.
     */
    function transferFrom(
        address,
        address _to,
        uint256 _tokenId
    ) public {
        mint(_tokenId, _to);
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool)
    {
        if (owner() == _owner && _owner == _operator) {
            return true;
        }

        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (
            owner() == _owner &&
            address(proxyRegistry.proxies(_owner)) == _operator
        ) {
            return true;
        }

        return false;
    }

    /**
     * Hack to get things to work automatically on OpenSea.
     * Use isApprovedForAll so the frontend doesn't have to worry about different method names.
     */
    function ownerOf(uint256) public view returns (address _owner) {
        return owner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 uTokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed uTokenId);
    event Approval(address indexed owner, address indexed approveder, uint256 indexed uTokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool bApproved);
    event NewStellar(uint256 indexed uTokenId, uint256 indexed uValue, string strAppear);
    event RemoveStellar(uint256 indexed uTokenId);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 uTokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 uTokenId) external;
    function safeTransferFrom(address from, address to, uint256 uTokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 uTokenId) external;

    function approve(address to, uint256 uTokenId) external;
    function getApproved(uint256 uTokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _uTokenId) external view returns (string memory);
}

contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Stellar is ERC721, ERC721Metadata, Ownable {

    using Strings for uint16;
    using Strings for uint256;

    address payable private m_addrOwner = payable(msg.sender);

    address private m_addrStellarFact;

    string private m_strName;

    string private m_strSymbol;
    
    bool public m_bMintingFinalized = false;

    uint256 public m_countMint;

    uint256 public m_countToken;

    uint256 private m_price = 0.001 ether;

    // Mapping from owner address to token ID.
    mapping (address => uint256) private m_mapTokens;

    // Mapping owner address to token count.
    mapping (address => uint256) private m_mapBalances;

    // Mapping from token ID to owner address.
    mapping (uint256 => address) private m_mapOwners;

    // Mapping token ID to value.
    mapping (uint256 => uint256) private m_mapValues;
    mapping (uint256 => uint256) private m_mapAppearance;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private m_mapTokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private m_mapOperatorApprovals;

    // bonus
    mapping (address => uint256) private m_mapBonus;
    
    uint32 public m_totalMergeNum = 0;
    uint32 constant U32SIZE = 16;
    // 前六个轨道支持2的5次方，第七个轨道还是2的4次方
    uint8[16] arrTrackBitCount = [5,5,5,5,5,5,4,4,4,4,4,4,4,4,4,4];  // [4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4]; 
    uint256[16] arrTrackBitShift;
    uint256[16] arrTrackBitFlag;
    uint8[16] public arrTrackRandWeight = [16,16,16, 17,16,16, 2,2,2,3, 2,2,2,2,2,2];
    string public m_baseURI = "http://43.130.64.52:8888/Stellar/";
 
    uint constant DAY_IN_SECONDS = 86400;
    // 每日merge后最高的记录
    uint    m_bonusDayTime = 0;
    address m_bonusDayAddress;
    uint256 m_bonusDayMass = 0;
    uint constant DAILY_TOP_BONUS = 1;
    // 每周merge后最高的记录
    uint    m_bonusWeekTime = 0;
    address m_bonusWeekAddress;
    uint256 m_bonusWeekMass = 0;
    uint constant WEEKLY_TOP_BONUS = 3;
    // Every five merge buy from office site will get 1 free Mass
    uint constant BUY_MASS_BONUS_NUM = 5;

    address proxyRegistryAddress;

    // modifier onlyOwner() {
    //     require(_msgSender() == m_addrOwner, "msg.sender is not Owner");
    //     _;
    // }
    
    constructor(address _proxyRegistryAddress) {
        proxyRegistryAddress = _proxyRegistryAddress;
        m_strName = "eStellar.";
        m_strSymbol = "es";
        uint32 u32BitShift = 0;
        for(uint32 i=0; i<U32SIZE; ++i) {
            arrTrackBitShift[i] = 2 ** u32BitShift;
            arrTrackBitFlag[i] = (2 ** arrTrackBitCount[i] - 1) *  arrTrackBitShift[i];
            u32BitShift += arrTrackBitCount[i];
        }
    }

    function toLast2HexString(uint i) public pure returns (string memory) {
        if (i == 0) return "00";
        uint mask = 15;
        bytes memory bstr = new bytes(2);
        for(uint32 j = 0; j< 2; ++j) {
            uint curr = (i & mask);
            bstr[1-j] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }
    
    function name() external view virtual override returns (string memory) {
        return m_strName;
    }

    function symbol() external view virtual override returns (string memory) {
        return m_strSymbol;
    }

    function totalSupply() public view returns (uint256) {
        return m_countToken;
    }

    // function _msgSender() internal view returns (address) {
    //     return msg.sender;
    // }

    function getMsgSender() external view returns (address) {
        return msg.sender;
    }
 
    //获取星期几 0~6
    function getWeekday(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }
    
    function getLastSunday(uint timestamp) public pure returns (uint) {
        return (((timestamp / DAY_IN_SECONDS + 4) / 7) * 7 + 4) * DAY_IN_SECONDS;
    }

    // uint public tTestNow = block.timestamp;
    // function testAddDay() public {
    //     tTestNow += DAY_IN_SECONDS;
    // }
    function getNowTime() internal view returns (uint) {
        // return tTestNow;
        return block.timestamp;
    }

    function getStellarFact() external view returns (address) {
        return m_addrStellarFact;
    }
    
    function setStellarFact(address addrFactory) external onlyOwner {
        m_addrStellarFact = addrFactory;
    }

    function checkRankBonus() internal {
        uint tNow = getNowTime();
        // 日榜结算
        if(m_bonusDayTime > 0 && m_bonusDayMass > 0) {
            if(tNow >= m_bonusDayTime + DAY_IN_SECONDS || getWeekday(tNow) != getWeekday(m_bonusDayTime)) {
                // 达到发放条件
                m_mapBonus[m_bonusDayAddress] += DAILY_TOP_BONUS;
                m_bonusDayTime = 0;
                m_bonusDayMass = 0;
            }
        }
        // 周榜结算
        if(m_bonusWeekTime > 0 && m_bonusWeekMass > 0) {
            if(tNow / DAY_IN_SECONDS >= (m_bonusWeekTime / DAY_IN_SECONDS  +  7) ) {
                // 达到发放条件
                m_mapBonus[m_bonusWeekAddress] += WEEKLY_TOP_BONUS;
                m_bonusWeekTime = 0;
                m_bonusWeekMass = 0;
            }
        }
    }

    function setRankBonus(address addr, uint256 mass) internal {
        uint tNow = getNowTime();
        // 日榜判定
        if(0 != getWeekday(tNow)) {
            if(0 == m_bonusDayTime) {
                m_bonusDayTime = tNow;
            }
            if(mass > m_bonusDayMass) {
                m_bonusDayMass = mass;
                m_bonusDayAddress = addr;
            }
        }
        // 周榜判定
        if(0 == m_bonusWeekTime) {
            m_bonusWeekTime = getLastSunday(tNow);
        }
        if(mass > m_bonusWeekMass) {
            m_bonusWeekMass = mass;
            m_bonusWeekAddress = addr;
        }
    }

    function _getSpHexAppearance(uint256 u256Appear) internal view returns (string memory) {
        bytes memory byteString;

        // 先高128位
        uint256 n256HighAppear = u256Appear / (2**128);
        if(n256HighAppear > 0) {
            for(uint32 i = 0; i < U32SIZE ; ++i) {
                uint256 _oneAppear = (n256HighAppear & arrTrackBitFlag[U32SIZE- i - 1]) / arrTrackBitShift[U32SIZE- i - 1];
                byteString = abi.encodePacked(byteString, toLast2HexString(_oneAppear));
            }
            byteString = abi.encodePacked(byteString,"00000000");
        }
        // 低128位
        u256Appear = u256Appear & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        for(uint32 i = 0; i < U32SIZE ; ++i) {
            uint256 _oneAppear = (u256Appear & arrTrackBitFlag[U32SIZE- i - 1]) / arrTrackBitShift[U32SIZE- i - 1];
            byteString = abi.encodePacked(byteString, toLast2HexString(_oneAppear));
        }

        return string(byteString);
    }

    function getSpHexAppearance(uint256 u256Appear) external view returns (string memory) {
        return _getSpHexAppearance(u256Appear);
    }

    function _getTokenHexAppearance(uint256 uTokenId) internal view returns (string memory) {
        return _getSpHexAppearance(m_mapAppearance[uTokenId]);
    }

    function getAllToken() external view returns (uint256[] memory) {
        uint256[] memory list = new uint[](m_countToken);
        uint uIndex = 0;
        for(uint256 i=1; i <= m_countMint; ++i) {
            if(m_mapValues[i] > 0) {
                list[uIndex] = i;
                ++uIndex;
            }
        }
        return list;
    }

    function tokenURI(uint256 uTokenId) external virtual view override returns (string memory) {
        require(_exists(uTokenId), "ERC721: operator query for nonexistent token");
        
        bytes memory byteString;
        byteString = abi.encodePacked(byteString, m_baseURI, "getTokenInfo.php?token=", uTokenId.toString());
        byteString = abi.encodePacked(byteString, "&mass=", m_mapValues[uTokenId].toString());
        byteString = abi.encodePacked(byteString, "&appear=", _getTokenHexAppearance(uTokenId));
        return string(byteString);
    }

    function contractURI() external view returns (string memory) {
        bytes memory byteString;
        byteString = abi.encodePacked(byteString, m_baseURI, "openseaInfo.php");
        return string(byteString);
    }

    function setBaseURI(string memory strBaseURI) external onlyOwner {
        m_baseURI = strBaseURI;
    }

    function getJson(uint256 uTokenId) public virtual view returns (string memory) {
        require(_exists(uTokenId), "ERC721: operator query for nonexistent token");
        uint256 uAppear = m_mapAppearance[uTokenId];
        uint256 uValue = m_mapValues[uTokenId];
        bytes memory byteString;
        byteString = abi.encodePacked(byteString, '[');
        bool bNoComma = true;
        for(uint256 i = 0; i<U32SIZE; ++i) {
            if(uValue > 0 && (uValue & 2**i) > 0) {
                if(bNoComma) {
                    bNoComma = false;
                } else {
                    byteString = abi.encodePacked(byteString, ',');
                }
                uint256 uTeamp = (uAppear  & arrTrackBitFlag[i]) / arrTrackBitShift[i];
                byteString = abi.encodePacked(byteString, '[', i.toString(), ',', uTeamp.toString(), ']');
            }
        }
        byteString = abi.encodePacked(byteString, ']'); 
        return string(byteString);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }    

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_ 
            || interfaceId == _ERC721_
            || interfaceId == _ERC2981_
            || interfaceId == _ERC721Metadata_;
    }

    function mint(uint256[][] memory vecValues) external onlyOwner {
        require(!m_bMintingFinalized, " minting is Finalized");

        uint256 index = m_countMint;

        for (uint256 i = 1; i <= vecValues.length; i++) {

            index = m_countMint + i;
            uint256 _value = vecValues[i-1][0];
            m_mapAppearance[index] = vecValues[i-1][1];
            m_mapValues[index] = _value;

            m_mapOwners[index] = m_addrOwner;

            emit Transfer(address(0), m_addrOwner, index);
            emit NewStellar(index, m_mapValues[index], _getTokenHexAppearance(index));
        }

        m_countMint += vecValues.length;
        m_countToken += vecValues.length;

        m_mapBalances[m_addrOwner] += vecValues.length;
    }

    function _genAppearance() internal view returns (uint256) {
        
        uint256 _appear = 0;
        uint256 _seed = getNowTime();
        for(uint32 i = 0; i< U32SIZE; ++i) {
            uint256 nRand = rand(arrTrackRandWeight[i], _seed);
            _seed += nRand*(i+1) + i;
            _appear |= (nRand * arrTrackBitShift[i]);
        }
        return _appear;
    }

    function mintToByFact(address to, uint256 mass) external {
        require(!m_bMintingFinalized, " minting is Finalized");
        require(_msgSender() == m_addrStellarFact || _msgSender() == owner()
                , "ERC721: mintToByFact caller is not factory");
        if(0 == m_mapTokens[to]) {
            uint256 index = m_countMint + 1;
            m_mapAppearance[index] = _genAppearance();
            m_mapValues[index] = mass;

            m_mapOwners[index] = to;

            emit Transfer(address(0), to, index);
            emit NewStellar(index, m_mapValues[index], _getTokenHexAppearance(index));
            m_countMint += 1;
            m_countToken += 1;
            m_mapBalances[to] += 1;
        } else {
            uint256 uToTokenId = m_mapTokens[to];
            _merge(to, uToTokenId, _genAppearance(), mass);
            emit NewStellar(uToTokenId, m_mapValues[uToTokenId],_getTokenHexAppearance(uToTokenId));
        }

    }

    function mintToByFact2(address to, uint256[] memory values) external {
        require(!m_bMintingFinalized, " minting is Finalized");
        require(_msgSender() == m_addrStellarFact || _msgSender() == owner()
                , "ERC721: mintToByFact2 caller is not factory");
        if(0 == m_mapTokens[to]) {
            uint256 index = m_countMint + 1;
            m_mapAppearance[index] = values[1];
            m_mapValues[index] = values[0];

            m_mapOwners[index] = to;

            emit Transfer(address(0), to, index);
            emit NewStellar(index, m_mapValues[index], _getTokenHexAppearance(index));
            m_countMint += 1;
            m_countToken += 1;
            m_mapBalances[to] += 1;
        } else {
            uint256 uToTokenId = m_mapTokens[to];
            _merge(to, uToTokenId, values[1], values[0]);
            emit NewStellar(uToTokenId, m_mapValues[uToTokenId],_getTokenHexAppearance(uToTokenId));
        }
    }

    function buyMass(uint256 mass) external payable {
        require(msg.value >= mass * m_price, "mass * price != msg.value");
        uint256 index = m_countMint + 1;
        uint256 _value = mass;
        // add bonus every BUY_MASS_BONUS_NUM mass;
        _value += uint256(mass / BUY_MASS_BONUS_NUM);
        m_mapAppearance[index] = _genAppearance();
        m_mapValues[index] = _value;

        m_mapOwners[index] = _msgSender();

        emit Transfer(address(0), _msgSender(), index);
        emit NewStellar(index, m_mapValues[index], _getTokenHexAppearance(index));

        m_countMint += 1;
        m_countToken += 1;

        m_mapBalances[_msgSender()] += 1;
    
    }

    function getPrice() public view returns (uint256) {
        return m_price;        
    }

    function setPrice(uint256 _price) external onlyOwner {
        m_price = _price;
    }

    function setTrackRandWeight(uint8[] memory arrWeight) external onlyOwner {
        require(arrWeight.length >= U32SIZE, "arrWeight.length < U32SIZE");
        uint8[U32SIZE] memory temp;
        for(uint32 i = 0; i< U32SIZE; ++i) {
            temp[i] = arrWeight[i];
        }
        arrTrackRandWeight = temp;
    }

    function withdraw() external onlyOwner {
        m_addrOwner.transfer(address(this).balance);
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function finalize() external onlyOwner {
        m_bMintingFinalized = true;
    }

    function safeTransferFrom(address from, address to, uint256 uTokenId) public virtual override {
        safeTransferFrom(from, to, uTokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 uTokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), uTokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, uTokenId);
        require(_checkOnERC721Received(from, to, uTokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 uTokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), uTokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, uTokenId);
    }

    function rand(uint256 _length, uint256 seed) internal view returns(uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, seed)));
        return random%_length;
    }


    function _merge(address to, uint256 uToTokenId, uint256 n256FromAppear, uint256 uFromValue) internal {
        uint256 uAddBonus = 0;

        m_totalMergeNum += 1;

        // bonus
        if(m_mapBonus[to] > 0) {
            uAddBonus += m_mapBonus[to]; 
            delete m_mapBonus[to];
        }
        uFromValue += uAddBonus;

        // TODO need modify
        // add value
        m_mapValues[uToTokenId] += uFromValue;
        uint256 n256ToAppear = m_mapAppearance[uToTokenId];
        uint256 n256NewAppear = 0;
        uint256 _seed = 0;
        for(uint32 i = 0; i< U32SIZE; ++i) {
            uint256 _fromAppear = n256FromAppear & arrTrackBitFlag[i];
            uint256 _toAppear = n256ToAppear & arrTrackBitFlag[i];
            uint256 _max = 0;
            uint256 _min = 0;

            if(_fromAppear < _toAppear) {
                _max = _toAppear;
                _min = _fromAppear;
            } else {
                _max = _fromAppear;
                _min = _toAppear;
            }
            // 75% choose max 
            // 20% choose min
            uint256 nRand = rand(100, _seed);
            _seed += nRand;
            if(nRand < 75) {
                n256NewAppear |= _max;
            }
            else if(nRand < 95) {
                n256NewAppear |= _min;
            } else {
                // rand a lower appear code
                if(_min > 0) {
                    _min = _min / arrTrackBitShift[i];
                    nRand = rand(_min, _seed);
                    _seed += nRand;
                    _min = nRand * arrTrackBitShift[i];
                    n256NewAppear |= _min;
                }
            }
        }
        // to's appear keep in high bits;
        n256NewAppear |= (n256ToAppear & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) * 2**128;
        m_mapAppearance[uToTokenId] = n256NewAppear;

        // 排行判定
        setRankBonus(to, m_mapValues[uToTokenId]);

    }

    function _transfer(address from, address to, uint256 uTokenId) internal {
        require(_exists(uTokenId), "ERC721: transfer attempt for nonexistent token");
        require(ownerOf(uTokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(from != to, "ERC721: transfer attempt to self");
        // if(to == _dead){
        //     _burn(uTokenId);
        //     return;
        // }

        _approve(address(0), uTokenId);

        checkRankBonus();

        if(m_mapTokens[to] == 0){            

            m_mapTokens[to] = uTokenId;
            m_mapOwners[uTokenId] = to;
            m_mapTokens[from] = 0;

            m_mapBalances[to] += 1;
            m_mapBalances[from] -= 1;

            // 排行判定
            setRankBonus(to, m_mapValues[uTokenId]);

            emit Transfer(from, to, uTokenId);
            return;
        }
        // merge
        uint256 uToTokenId = m_mapTokens[to];
        
        _merge(to, uToTokenId, m_mapAppearance[uTokenId], m_mapValues[uTokenId]);

        m_mapBalances[to] += 1;
        m_mapBalances[from] -= 1;
        // remove old owner(from)'s tokenid
        m_mapTokens[from] = 0;
        delete m_mapOwners[uTokenId];
        // remove tokenid
        delete m_mapValues[uTokenId];
        delete m_mapAppearance[uTokenId];
        m_countToken -= 1;
        
        emit Transfer(from, to, uTokenId);
        emit NewStellar(uToTokenId, m_mapValues[uToTokenId],_getTokenHexAppearance(uToTokenId));
        emit RemoveStellar(uTokenId);
    }

    function getProjOwner() external view virtual returns (address) {
        return m_addrOwner;
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return m_mapBalances[owner];
    }

    function ownerOf(uint256 uTokenId) public view override returns (address) {
        require(_exists(uTokenId), "ERC721: owner query for nonexistent token");        
        return m_mapOwners[uTokenId];
    }

    function getValueOf(uint256 uTokenId) external view virtual returns (uint256) {
        return m_mapValues[uTokenId];
    }

    function getAppearanceOf(uint256 uTokenId) external view virtual returns (uint256) {
        return m_mapAppearance[uTokenId];
    }

    function getHexAppearanceOf(uint256 uTokenId) external view virtual returns (string memory) {
        return _getTokenHexAppearance(uTokenId);
    }
        
    function getTokenOf(address owner) external view virtual returns (uint256) {
        uint256 token = m_mapTokens[owner];
        return token;
    }

    function approve(address to, uint256 uTokenId) public virtual override {
        address owner = ownerOf(uTokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        m_mapTokenApprovals[uTokenId] = to;
        emit Approval(owner, to, uTokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        m_mapTokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }
    
    function getApproved(uint256 uTokenId) public view virtual override returns (address) {
        require(_exists(uTokenId), "ERC721: operator query for nonexistent token");       
        return m_mapTokenApprovals[uTokenId];
    }

    function setApprovalForAll(address operator, bool bApproved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        m_mapOperatorApprovals[_msgSender()][operator] = bApproved;
        emit ApprovalForAll(_msgSender(), operator, bApproved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return m_mapOperatorApprovals[owner][operator];
    }

    function _exists(uint256 uTokenId) internal view returns (bool) {
        return m_mapValues[uTokenId] != 0;
    }

    function _isApprovedOrOwner(address operator, uint256 uTokenId) internal view virtual returns (bool) {
        require(_exists(uTokenId), "ERC721: operator query for nonexistent token");

        address owner = ownerOf(uTokenId);
        return (operator == owner || getApproved(uTokenId) == operator || isApprovedForAll(owner, operator));
    }

    function burn(uint256 uTokenId) public {
        require(_isApprovedOrOwner(_msgSender(), uTokenId), "ERC721: caller is not owner nor approved");
        _burn(uTokenId);
    }

    function _burn(uint256 uTokenId) internal {
        address owner = ownerOf(uTokenId);
        _approve(address(0), uTokenId);

        delete m_mapTokens[owner];
        delete m_mapOwners[uTokenId];
        delete m_mapValues[uTokenId];
        delete m_mapAppearance[uTokenId];

        m_countToken -= 1;
        m_mapBalances[owner] -= 1;        

        emit Transfer(owner, address(0), uTokenId);
        emit RemoveStellar(uTokenId);
    }

    function addBonus(address[] memory addr, uint256[] memory values)  external onlyOwner {
        uint256 count = addr.length;
        if(count > values.length) {
            count = values.length;
        }
        for(uint256 i=0; i < count; ++i) {
            m_mapBonus[addr[i]] += values[i];
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;

/**
 * This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface FactoryERC721 {
    /**
     * Returns the name of this factory.
     */
    function name() external view returns (string memory);

    /**
     * Returns the symbol for this factory.
     */
    function symbol() external view returns (string memory);

    /**
     * Number of options the factory supports.
     */
    function numOptions() external view returns (uint256);

    /**
     * @dev Returns whether the option ID can be minted. Can return false if the developer wishes to
     * restrict a total supply per option ID (or overall).
     */
    function canMint(uint256 _optionId) external view returns (bool);

    /**
     * @dev Returns a URL specifying some metadata about the option. This metadata can be of the
     * same structure as the ERC721 metadata.
     */
    function tokenURI(uint256 _optionId) external view returns (string memory);

    /**
     * Indicates that this is a factory contract. Ideally would use EIP 165 supportsInterface()
     */
    function supportsFactoryInterface() external view returns (bool);

    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId the option id
     * @param _toAddress address of the future owner of the asset(s)
     */
    function mint(uint256 _optionId, address _toAddress) external;
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