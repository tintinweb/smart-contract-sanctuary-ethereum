//SPDX-License-Identifier: MIT

import "./ERC721Upgradeable.sol";
import "./Counters.sol";
import "./IERC20.sol";
import "./StringsUpgradeable.sol";
import "./Initializable.sol";
import "./OwnableUpgradable.sol";
import "./ContextUpgradeable.sol";

pragma solidity ^0.8.0;

contract ChadInuVIPClub is Initializable, OwnableUpgradeable, ERC721Upgradeable {
    using Counters for Counters.Counter;

    struct VIPCardEntity {
        uint256 creationTime;
        address account;
        string referrerCode;
        uint256 rewardAmount;
        bool isReferred;
        bool isOutDeadline;
    }
    
    mapping(address => string[]) private _subRefOfUser;
    mapping(string => VIPCardEntity) private _vipCardOfUser;
    mapping(address => string) private _userOfAccount;
    mapping(address => uint256) private _ownerOfId;
    mapping(address => bool) public _isWhitelisted;

    Counters.Counter private _tokenIds;
    mapping (uint256 => string) private _tokenURIs;

    IERC20 public token;

    uint256 public refFee;
    uint256 public escowFee;
    uint256 public primaryFee;

    address public secondaryDevAddress;

    uint256 public referralDeadline;
    uint256 public mintingPrice;
    uint256 public mintingPriceWithRef;
    string public baseTokenURI;
    
    event NFTMinted (
        uint256 tokenId,
        address account,
        string usercode,
        string referrerCode,
        string metadataUri
    );
 
    function initialize()  public initializer {
        __ERC721_init_unchained("Chadinu VIP Card", "VIP Card");
        __Ownable_init_unchained();
        
        refFee = 33;
        escowFee = 33;
        primaryFee = 75;

        secondaryDevAddress = 0xC040e348fC48Ecd2ab355499211BF208B3891837;
        referralDeadline = 86400 * 14;
        mintingPrice = 2 * 10**17;
        mintingPriceWithRef = 15 * 10**16;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(from == address(0), "You can't transfer this NFT.");
        
        super._transfer( from, to, tokenId );
    }

    function mintNFT(address owner, string memory metadataURI) internal returns (uint256)
    {
        _tokenIds.increment();
        uint256 id = _tokenIds.current();
        _safeMint( owner, id );
        _setTokenURI( id, metadataURI );
        return id;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];

        // If there is no base URI, return the token URI.
        if (bytes(baseTokenURI).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked( baseTokenURI, _tokenURI ));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked( baseTokenURI, StringsUpgradeable.toString(tokenId) ));
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function MintVIPCard(
        string memory usercode, 
        string memory metadataURI
    ) 
        external 
        payable 
        returns (uint256) 
    {
        require(msg.value >= mintingPrice || _isWhitelisted[msg.sender], "Insufficient Fund");
        payToMintWithoutReferrer( _msgSender(), usercode );
        uint256 id = mintNFT( _msgSender(), metadataURI );
        _ownerOfId[_msgSender()] = id;
        if (msg.value > mintingPrice) payable(_msgSender()).transfer(msg.value - mintingPrice);
        emit NFTMinted( id, _msgSender(), usercode, "", metadataURI );
        return id;
    }

    function MintVIPCardWithReferreral(
        string memory usercode, 
        string memory referrerCode, 
        string memory metadataURI
    ) 
        external 
        payable 
        returns (uint256) 
    {
        require(msg.value >= mintingPriceWithRef, "Insufficient Fund");

        payToMintWithReferrer( _msgSender(), usercode, referrerCode );
        uint256 id = mintNFT( _msgSender(), metadataURI );
        _ownerOfId[_msgSender()] = id;
        if (msg.value > mintingPriceWithRef) payable(_msgSender()).transfer(msg.value - mintingPriceWithRef);

        emit NFTMinted( id, _msgSender(), usercode, referrerCode, metadataURI );
        return id;
    }

    function payToMintWithoutReferrer(address creator, string memory usercode) internal {
        require(bytes(_userOfAccount[creator]).length < 2, "Account has already minted an NFT.");
        require(bytes(usercode).length > 1 && bytes(usercode).length < 16, "ERROR:  user code length is invalid");
        require(creator != address(0), "CSHT:  zero address can't create");
        require(_vipCardOfUser[usercode].account == address(0), "user code is already used");

        _vipCardOfUser[usercode] = VIPCardEntity({
            creationTime: block.timestamp,
            account: creator,
            referrerCode: "",
            rewardAmount: 0,
            isReferred: false,
            isOutDeadline: false
        });
        _userOfAccount[creator] = usercode;

        if (_isWhitelisted[creator]) return;
        
        payable(secondaryDevAddress).transfer(mintingPrice);
    }

    function payToMintWithReferrer(address creator, string memory usercode, string memory referrerCode) internal returns (bool) {
        require(bytes(_userOfAccount[creator]).length < 2, "Account has already minted an NFT.");
        require(bytes(usercode).length > 1 && bytes(usercode).length < 16, "ERROR:  user code length is invalid");
        require(bytes(referrerCode).length > 1 && bytes(referrerCode).length < 16, "ERROR:  referrer code length is invalid");
        require(_vipCardOfUser[usercode].account == address(0), "usercode is already used");
        require(creator != address(0), "CSHT:  creation from the zero address");
        require(_vipCardOfUser[referrerCode].account != address(0), "referrer code is not exisiting");
        require(_vipCardOfUser[referrerCode].account != creator, "creator couldn't be same as referrer");

        uint256 escrowAmount = (mintingPriceWithRef * escowFee) / 100;
        uint256 refAmount = (mintingPriceWithRef * refFee) / 100;
        uint256 devAmount = mintingPriceWithRef - escrowAmount - refAmount;

        VIPCardEntity memory _ref = _vipCardOfUser[referrerCode];
        _subRefOfUser[_ref.account].push(usercode);

        if (_ref.isOutDeadline != true && bytes(_ref.referrerCode).length > 1)
        {
            VIPCardEntity storage _refT = _vipCardOfUser[referrerCode];
            if (block.timestamp - _ref.creationTime < referralDeadline) {
                if(_ref.rewardAmount > 0)
                    payable(_vipCardOfUser[_ref.referrerCode].account).transfer(_ref.rewardAmount);
                _refT.isReferred = true;
            } else {
                _refT.isReferred = false;
            }
            _refT.isOutDeadline = true;
        }

        if (mintingPriceWithRef > 100) {
            payable(_ref.account).transfer(refAmount);
            payable(secondaryDevAddress).transfer(devAmount);
        }

        _vipCardOfUser[usercode] = VIPCardEntity({
            creationTime: block.timestamp,
            account: creator,
            referrerCode: referrerCode,
            rewardAmount: escrowAmount,
            isReferred: false,
            isOutDeadline: false
        });
        _userOfAccount[creator] = usercode;

        return true;
    }

    function isCodeAvailable(string memory code) external view returns(bool) {
        return ( 
            _vipCardOfUser[code].creationTime==0 && 
            bytes(code).length > 1 && 
            bytes(code).length < 16
        );              
    }
    
    function addWhitelist(address account, bool value)
        external
    {
        require(msg.sender == address(token) || msg.sender == owner(), "Access Denied");
        _isWhitelisted[account] = value;
    }

    function checkWhitelisted(address account)
        external
        view
        returns(bool)
    {
        return _isWhitelisted[account];
    }

    function getSubReferralLength(address account) external view returns (uint256) {
        return _subRefOfUser[account].length;
    }

    function getSubReferral(address account, uint16 startIndex, uint16 endIndex) external view returns (string memory) {
        require(_subRefOfUser[account].length > endIndex, "GET SUB REFERRERS: Out of Range");
        string[] memory subRefs = _subRefOfUser[account];
        VIPCardEntity memory _ref;
        string memory refsStr = "";
        string memory separator = "#";
        
        for (uint256 i=startIndex; i < endIndex+1; i++) {
            _ref = _vipCardOfUser[subRefs[i]];
            refsStr = string(abi.encodePacked(
                refsStr, 
                separator, _userOfAccount[_ref.account], 
                separator, toAsciiString(_ref.account), 
                separator, StringsUpgradeable.toString(_ref.creationTime), 
                separator, StringsUpgradeable.toString(_ref.rewardAmount)
            ));

            if (_ref.isReferred == true) {
                string[] memory childRefStrs = _subRefOfUser[_ref.account];
                VIPCardEntity memory _childRef = _vipCardOfUser[childRefStrs[0]];
                refsStr = string(abi.encodePacked(refsStr, separator, "1", separator, StringsUpgradeable.toString(_childRef.creationTime)));
            } else {
                refsStr = string(abi.encodePacked(refsStr, separator, "0", separator, "0"));
            }
            if (_ref.isOutDeadline == true) {
                refsStr = string(abi.encodePacked(refsStr, separator, "1"));
            } else {
                refsStr = string(abi.encodePacked(refsStr, separator, "0"));
            }
        }

        return refsStr;
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    receive() external payable {}

    function boostProject(uint256 amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function setBaseToken(address newAddress) external onlyOwner {
        require(newAddress!=address(token), "New token address is same as old one");
        token = IERC20(newAddress);
    }

    function getbalanceOf(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    function getIdOfUser(address account) external view returns (uint256) {
        require(account != address(0), "address CAN'T BE ZERO");
        return _ownerOfId[account];
    }

    function getUsercode(address account) external view returns (string memory) {
        return _userOfAccount[account];
    }

    function getMintPrice() external view returns (uint256) {
        return mintingPrice;
    }

    function setMintingPrice(uint256 newMintingPrice) external onlyOwner {
        mintingPrice = newMintingPrice;
    }

    function getMintPriceWithRef() external view returns (uint256) {
        return mintingPriceWithRef;
    }

    function setMintingPriceWithRef(uint256 newMintingPriceWithRef) external onlyOwner {
        mintingPriceWithRef = newMintingPriceWithRef;
    }

    function getSecondaryDevAddress() external view returns (address) {
        return secondaryDevAddress;
    }

    function setSecondaryDevAddress(address newAddress) external onlyOwner {
        require(newAddress!=secondaryDevAddress, "New secondary dev address is same as old one");
        secondaryDevAddress = newAddress;
    }

    function getReferreralDeadline() external view returns (uint256) {
        return referralDeadline;
    }
    
    function changeReferreralDeadline(uint256 newDeadline) external onlyOwner {
        referralDeadline = newDeadline;
    }

    function changeRefFee(uint256 value) external onlyOwner {
        refFee = value;
    }

    function changeEscowFee(uint256 value) external onlyOwner {
        escowFee = value;
    }

    function changePrimaryFee(uint256 value) external onlyOwner {
        primaryFee = value;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }
}