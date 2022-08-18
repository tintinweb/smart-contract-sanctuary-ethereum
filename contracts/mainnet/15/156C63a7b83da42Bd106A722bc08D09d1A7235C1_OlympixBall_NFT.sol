// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract OlympixBall_NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    bool public paused = false;

    string public baseURI;
    string public baseExtension = ".json";

    mapping(address => bool) public ogDiscountWhitelisted;
    mapping(address => bool) public discountWhitelisted;
    mapping(address => bool) public freeWhitelisted;

    mapping(address => uint256) public ogDiscountMintCount;
    mapping(address => uint256) public discountMintCount;
    mapping(address => uint256) public freeMintCount;

    uint256 public cost = 0.08 ether;
    uint256 constant public maxSupply = 6000;
    uint256 public maxMintAmount = 20;

    uint256 public maxFreeMintAmount = 1;
    uint256 public maxOgMintAmount = 2;
    uint256 public maxWlMintAmount = 5;

    uint256 public discountCost = 0.05 ether;
    uint256 public ogDiscountCost = 0.04 ether;

    uint256 public discountStartHeight;
    uint256 public freeStartHeight;
    uint256 public startHeight;

    uint256 public selfSetupStartBlock;
    uint256 public selfSetupEndBlock;
    uint256 public selfSetupFreeMintMaxLimit;
    uint256 public selfSetupOgMintMaxLimit;
    uint256 public selfSetupWlMintMaxLimit;

    uint256 public selfSetupFreeMintCurrentCount;
    uint256 public selfSetupOgMintCurrentCount;
    uint256 public selfSetupWlMintCurrentCount;

    uint256 public selfSetupFreeMintTotalCount;
    uint256 public selfSetupOgMintTotalCount;
    uint256 public selfSetupWlMintTotalCount;

    address public  foundationAddress;

    mapping(uint256 => string) public tokenIdMap;

    event setCostEvent(uint256 cost);
    event setMaxMintAmountEvent(uint256 _newMaxMintAmount);
    event setBaseURIEvent(string _newBaseURI);
    event setBaseExtensionEvent(string _newBaseExtension);
    event setPauseEvent(bool _state);
    event setFreeWhitelistUserEvent(address _user);
    event setDiscountWhitelistUserEvent(address _user);
    event setOgDiscountWhitelistUserEvent(address _user);
    event setFreeWhitelistUserListEvent(uint256 userLen);
    event setDiscountWhitelistUserListEvent(uint256 userLen);
    event setOgDiscountWhitelistUserListEvent(uint256 userLen);
    event setOgDiscountCostEvent(uint256 _ogDiscountCost);
    event setDiscountCostEvent(uint256 _discountCost);
    event setStartHeightEvent(uint256 _startHeight);
    event setFreeStartHeightEvent(uint256 _freeStartHeight);
    event setDiscountStartHeightEvent(uint256 _discountStartHeight);
    event setMaxFreeMintAmountEvent(uint256 _maxFreeMintAmount);
    event setMaxOgMintAmountEvent(uint256 _maxOgMintAmount);
    event setMaxWlMintAmountEvent(uint256 _maxWlMintAmount);
    event removeDiscountWhitelistUserEvent(address _user);
    event setFoundationAddressEvent(address _user);
    event removeFreeWhitelistUserEvent(address _user);
    event removeOgDiscountWhitelistUserEvent(address _user);
    event setFreeWhitelistBySelfEvent(address _user);
    event setOgDiscountWhitelistBySelfEvent(address _user);
    event setDiscountWhitelistBySelfEvent(address _user);
    event resetSelfWhiteListParamEvent(uint256 _selfSetupStartBlock, uint256 _selfSetupEndBlock,
        uint256 _selfSetupFreeMintMaxLimit, uint256 _selfSetupOgMintMaxLimit, uint256 _selfSetupWlMintMaxLimit);
    event setSelfWhiteListParamEvent(uint256 _selfSetupStartBlock, uint256 _selfSetupEndBlock,
        uint256 _selfSetupFreeMintMaxLimit, uint256 _selfSetupOgMintMaxLimit, uint256 _selfSetupWlMintMaxLimit);

    constructor(
        uint256 _startHeight,
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        startHeight = _startHeight;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    // public
    function mint(address _to, uint256 _mintAmount) external payable {
        uint256 supply = totalSupply();

        require(!paused, "mint paused");
        require(_mintAmount > 0, "mint amount need > 0 ");
        require(_mintAmount <= maxMintAmount, "mint amount exceed max limit ");
        require(supply + _mintAmount <= maxSupply, "mint amount exceed max supply ");

        if (msg.sender != owner()) {
            uint256 freeMintCountTmp = freeMintCount[msg.sender];
            uint256 maxFreeMintAmountTmp = maxFreeMintAmount;

            uint256 costRemain = 0;
            if (freeWhitelisted[msg.sender] == true && freeMintCountTmp < maxFreeMintAmountTmp) {
                require(block.number >= freeStartHeight, " free mint  not start! ");
                require(freeMintCountTmp + _mintAmount <= maxFreeMintAmountTmp, " mint exceed max free limit ! ");
                freeMintCount[msg.sender] = freeMintCountTmp + _mintAmount;
                costRemain = msg.value;
            }
            else {
                uint256 ogDiscountMintCountTmp = ogDiscountMintCount[msg.sender];
                uint256 maxOgMintAmountTmp = maxOgMintAmount;
                uint256 discountStartHeightTmp = discountStartHeight;

                if (ogDiscountWhitelisted[msg.sender] == true && ogDiscountMintCountTmp < maxOgMintAmountTmp) {
                    require(block.number >= discountStartHeightTmp, " og  discount mint  not start! ");
                    require(ogDiscountMintCountTmp + _mintAmount <= maxOgMintAmountTmp, " mint exceed max og limit ! ");
                    require(msg.value >= ogDiscountCost * _mintAmount, " eth not  enough ");

                    ogDiscountMintCount[msg.sender] = ogDiscountMintCountTmp + _mintAmount;
                    costRemain = msg.value - ogDiscountCost * _mintAmount;
                }
                else {
                    uint256 discountMintCountTmp = discountMintCount[msg.sender];
                    uint256 maxWlMintAmountTmp = maxWlMintAmount;

                    if (discountWhitelisted[msg.sender] == true && discountMintCountTmp < maxWlMintAmountTmp) {
                        require(block.number >= discountStartHeightTmp, " wl discount mint  not start! ");
                        require(discountMintCountTmp + _mintAmount <= maxWlMintAmountTmp, " mint exceed max wl limit ! ");
                        require(msg.value >= discountCost * _mintAmount, " eth not  enough ");

                        discountMintCount[msg.sender] = discountMintCountTmp + _mintAmount;
                        costRemain = msg.value - discountCost * _mintAmount;
                    } else {
                        require(block.number >= startHeight, " not start! ");
                        require(msg.value >= cost * _mintAmount, " eth not  enough ");

                        costRemain = msg.value - cost * _mintAmount;
                    }
                }
            }
            if (costRemain > 0) {
                (bool os,) = payable(msg.sender).call{value : costRemain}("");
                require(os, "return coin error");
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }

    }

    function walletOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }

    //only owner
    function setCost(uint256 _newCost) external onlyOwner {
        require(_newCost > 0,
            "cost must great than zero "
        );
        cost = _newCost;
        emit setCostEvent(_newCost);
    }


    function setTokenIdProp(uint256 _tokenId, string memory _prop) public onlyOwner {
        tokenIdMap[_tokenId] = _prop;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) external onlyOwner {
        require(_newMaxMintAmount > 0,
            "maxMintAmount must great than zero "
        );
        maxMintAmount = _newMaxMintAmount;
        emit setMaxMintAmountEvent(_newMaxMintAmount);
    }



    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
        emit setBaseURIEvent(_newBaseURI);
    }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner {
        baseExtension = _newBaseExtension;
        emit setBaseExtensionEvent(_newBaseExtension);
    }

    function pause(bool _state) external onlyOwner {
        paused = _state;
        emit setPauseEvent(_state);
    }

    function setFreeWhitelistUser(address _user) external onlyOwner {
        require(_user != address(0), 'user is the zero address');
        freeWhitelisted[_user] = true;
        emit setFreeWhitelistUserEvent(_user);
    }

    function setDiscountWhitelistUser(address _user) external onlyOwner {
        require(_user != address(0), 'user is the zero address');
        discountWhitelisted[_user] = true;
        emit setDiscountWhitelistUserEvent(_user);
    }

    function setOgDiscountWhitelistUser(address _user) external onlyOwner {
        require(_user != address(0), 'user is the zero address');
        ogDiscountWhitelisted[_user] = true;
        emit setOgDiscountWhitelistUserEvent(_user);
    }

    function setFreeWhitelistUserList(address[] memory users) external onlyOwner {
        require(users.length > 0,
            "users.length must great than zero "
        );
        for (uint i = 0; i < users.length; i ++) {
            freeWhitelisted[users[i]] = true;
        }
        emit setFreeWhitelistUserListEvent(users.length);
    }

    function setDiscountWhitelistUserList(address[] memory users) external onlyOwner {
        require(users.length > 0,
            "users.length must great than zero "
        );
        for (uint i = 0; i < users.length; i ++) {
            discountWhitelisted[users[i]] = true;
        }
        emit setDiscountWhitelistUserListEvent(users.length);
    }

    function setOgDiscountWhitelistUserList(address[] memory users) external onlyOwner {
        require(users.length > 0,
            "users.length must great than zero "
        );
        for (uint i = 0; i < users.length; i ++) {
            ogDiscountWhitelisted[users[i]] = true;
        }
        emit setOgDiscountWhitelistUserListEvent(users.length);
    }

    function setOgDiscountCost(uint256 _ogDiscountCost) external onlyOwner {
        require(_ogDiscountCost > 0,
            "cost must great than zero "
        );
        ogDiscountCost = _ogDiscountCost;
        emit setOgDiscountCostEvent(_ogDiscountCost);
    }

    function setDiscountCost(uint256 _discountCost) external onlyOwner {
        require(_discountCost > 0,
            "cost must great than zero "
        );
        discountCost = _discountCost;
        emit setDiscountCostEvent(_discountCost);
    }

    function setStartHeight(uint256 _startHeight) external onlyOwner {
        require(_startHeight > 0,
            "start height must great than zero "
        );
        startHeight = _startHeight;
        emit setStartHeightEvent(_startHeight);
    }

    function setFreeStartHeight(uint256 _freeStartHeight) external onlyOwner {
        require(_freeStartHeight > 0,
            "start height must great than zero "
        );
        freeStartHeight = _freeStartHeight;
        emit setFreeStartHeightEvent(_freeStartHeight);
    }

    function setDiscountStartHeight(uint256 _discountStartHeight) external onlyOwner {
        require(_discountStartHeight > 0,
            "start height must great than zero "
        );
        discountStartHeight = _discountStartHeight;
        emit setDiscountStartHeightEvent(_discountStartHeight);
    }

    function setMaxFreeMintAmount(uint256 _maxFreeMintAmount) external onlyOwner {
        require(_maxFreeMintAmount <= 10,
            "per person free amount exceed max limit "
        );
        maxFreeMintAmount = _maxFreeMintAmount;
        emit setMaxFreeMintAmountEvent(_maxFreeMintAmount);
    }

    function setMaxOgMintAmount(uint256 _maxOgMintAmount) external onlyOwner {
        require(_maxOgMintAmount <= 20,
            "per person og amount exceed max limit "
        );
        maxOgMintAmount = _maxOgMintAmount;
        emit setMaxOgMintAmountEvent(_maxOgMintAmount);
    }

    function setMaxWlMintAmount(uint256 _maxWlMintAmount) external onlyOwner {
        require(_maxWlMintAmount <= 50,
            "per person wl amount exceed max limit "
        );
        maxWlMintAmount = _maxWlMintAmount;
        emit setMaxWlMintAmountEvent(_maxWlMintAmount);
    }

    function removeDiscountWhitelistUser(address _user) external onlyOwner {
        require(_user != address(0), 'user is the zero address');
        discountWhitelisted[_user] = false;
        emit removeDiscountWhitelistUserEvent(_user);
    }

    function setFoundationAddress(address _user) external onlyOwner {
        require(_user != address(0), 'user is the zero address');
        foundationAddress = _user;
        emit setFoundationAddressEvent(_user);
    }

    function removeFreeWhitelistUser(address _user) external onlyOwner {
        require(_user != address(0), 'user is the zero address');
        freeWhitelisted[_user] = false;
        emit removeFreeWhitelistUserEvent(_user);
    }

    function removeOgDiscountWhitelistUser(address _user) external onlyOwner {
        require(_user != address(0), 'user is the zero address');
        ogDiscountWhitelisted[_user] = false;
        emit removeOgDiscountWhitelistUserEvent(_user);
    }

    function withdraw() external onlyOwner {
        (bool os,) = payable(owner()).call{value : address(this).balance}("");
        require(os, "withdraw  error");
    }

    function withdrawFoundation() external {
        address foundationAddressTmp = foundationAddress;
        require(foundationAddressTmp != address(0),
            "foundationAddress can not be  zero address"
        );
        (bool os,) = payable(foundationAddressTmp).call{value : address(this).balance}("");
        require(os, "withdraw to foundation error");
    }

    function setFreeWhitelistBySelf(address _user) external {
        uint256 selfSetupFreeMintCurrentCountTmp = selfSetupFreeMintCurrentCount;
        require(_user != address(0), 'user is the zero address');
        require(block.number > selfSetupStartBlock && block.number < selfSetupEndBlock,
            "set had not start or  already ended"
        );
        require(selfSetupFreeMintCurrentCountTmp < selfSetupFreeMintMaxLimit,
            "set count exceed max  limit "
        );
        if (freeWhitelisted[_user] != true) {
            freeWhitelisted[_user] = true;
            selfSetupFreeMintCurrentCount = selfSetupFreeMintCurrentCountTmp + 1;
            selfSetupFreeMintTotalCount = selfSetupFreeMintTotalCount + 1;
        }
        emit setFreeWhitelistBySelfEvent(_user);
    }

    function setOgDiscountWhitelistBySelf(address _user) external {
        uint256 selfSetupOgMintCurrentCountTmp = selfSetupOgMintCurrentCount;
        require(_user != address(0), 'user is the zero address');
        require(block.number > selfSetupStartBlock && block.number < selfSetupEndBlock,
            "set had not start or  already ended"
        );
        require(selfSetupOgMintCurrentCountTmp < selfSetupOgMintMaxLimit,
            "set count exceed max  limit "
        );
        if (ogDiscountWhitelisted[_user] != true) {
            ogDiscountWhitelisted[_user] = true;
            selfSetupOgMintCurrentCount = selfSetupOgMintCurrentCountTmp + 1;
            selfSetupOgMintTotalCount = selfSetupOgMintTotalCount + 1;
        }
        emit setOgDiscountWhitelistBySelfEvent(_user);
    }

    function setDiscountWhitelistBySelf(address _user) external {
        uint256 selfSetupWlMintCurrentCountTmp = selfSetupWlMintCurrentCount;
        require(block.number > selfSetupStartBlock && block.number < selfSetupEndBlock,
            "set had not start or  already ended"
        );
        require(selfSetupWlMintCurrentCountTmp < selfSetupWlMintMaxLimit,
            "set count exceed max  limit "
        );
        if (discountWhitelisted[_user] != true) {
            discountWhitelisted[_user] = true;
            selfSetupWlMintCurrentCount = selfSetupWlMintCurrentCountTmp + 1;
            selfSetupWlMintTotalCount = selfSetupWlMintTotalCount + 1;
        }
        emit setDiscountWhitelistBySelfEvent(_user);
    }

    function resetSelfWhiteListParam(uint256 _selfSetupStartBlock, uint256 _selfSetupEndBlock,
        uint256 _selfSetupFreeMintMaxLimit, uint256 _selfSetupOgMintMaxLimit, uint256 _selfSetupWlMintMaxLimit) external onlyOwner {
        require(_selfSetupStartBlock < _selfSetupEndBlock,
            "start must before end "
        );
        require(_selfSetupFreeMintMaxLimit <= 100,
            "free amount exceed max limit "
        );
        require(_selfSetupFreeMintMaxLimit * maxFreeMintAmount <= maxSupply,
            "free amount exceed max limit "
        );
        require(_selfSetupOgMintMaxLimit <= 700,
            "og amount exceed max limit "
        );
        //        require(_selfSetupWlMintMaxLimit < 2000,
        //            "wl amount exceed max limit "
        //        );
        selfSetupStartBlock = _selfSetupStartBlock;
        selfSetupEndBlock = _selfSetupEndBlock;
        selfSetupFreeMintMaxLimit = _selfSetupFreeMintMaxLimit;
        selfSetupOgMintMaxLimit = _selfSetupOgMintMaxLimit;
        selfSetupWlMintMaxLimit = _selfSetupWlMintMaxLimit;

        selfSetupFreeMintCurrentCount = 0;
        selfSetupOgMintCurrentCount = 0;
        selfSetupWlMintCurrentCount = 0;
        emit resetSelfWhiteListParamEvent(_selfSetupStartBlock, _selfSetupEndBlock,
            _selfSetupFreeMintMaxLimit, _selfSetupOgMintMaxLimit, _selfSetupWlMintMaxLimit);
    }

    function setSelfWhiteListParam(uint256 _selfSetupStartBlock, uint256 _selfSetupEndBlock,
        uint256 _selfSetupFreeMintMaxLimit, uint256 _selfSetupOgMintMaxLimit, uint256 _selfSetupWlMintMaxLimit) external onlyOwner {
        require(_selfSetupStartBlock < _selfSetupEndBlock,
            "start must before end "
        );
        require(_selfSetupFreeMintMaxLimit <= 100,
            "free amount exceed max limit "
        );
        require(_selfSetupFreeMintMaxLimit * maxFreeMintAmount <= maxSupply,
            "free amount exceed max limit "
        );
        require(_selfSetupOgMintMaxLimit <= 700,
            "og amount exceed max limit "
        );
        //        require(_selfSetupWlMintMaxLimit < 2000,
        //            "wl amount exceed max limit "
        //        );
        selfSetupStartBlock = _selfSetupStartBlock;
        selfSetupEndBlock = _selfSetupEndBlock;
        selfSetupFreeMintMaxLimit = _selfSetupFreeMintMaxLimit;
        selfSetupOgMintMaxLimit = _selfSetupOgMintMaxLimit;
        selfSetupWlMintMaxLimit = _selfSetupWlMintMaxLimit;

        emit setSelfWhiteListParamEvent(_selfSetupStartBlock, _selfSetupEndBlock,
            _selfSetupFreeMintMaxLimit, _selfSetupOgMintMaxLimit, _selfSetupWlMintMaxLimit);

    }

}