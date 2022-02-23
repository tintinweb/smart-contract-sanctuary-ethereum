// SPDX-License-Identifier: MIT

//··········································
//··········································
//········_________·___·___····_________····
//······/  ______  \\  \\  \·/  ______  \···
//·····/__/·····/  //  //  //__/·····/  /···
//····_________/  //  //  /_________/  /····
//···/  _________//  //  //  _________/·····
//··/  /________ /  //  //  /________·······
//·/__/\_______//__//__//__/\_______/·∅·RUN·
//··········································
//··········································

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./PaymentSplitter.sol";

interface RP {
    function balanceOf(address account, uint256 id) external returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external returns (uint256[] memory);
    function burnFromRedeem(address account, uint256[] calldata ids, uint256[] calldata amounts) external;
}

contract CryptorunnerNFT is ERC721Enumerable, Ownable, PaymentSplitter {
    string  public              baseURI;
    string  public              provenance;
    
    address public              proxyRegistryAddress;
    address public              rootPassAddress;

    bool    public              saleStatus;
    uint256 public constant     MAX_SUPPLY          = 10560;
    uint256 public              MAX_GIVEAWAY        = 100;

    uint256 public constant     MAX_PER_TX          = 20;
    uint256 public              priceInWei          = 0.1 ether;

    mapping(address => bool) public projectProxy;

    constructor(
        string memory _baseURI, 
        address _proxyRegistryAddress, 
        address _rootPassAddress,
        address[] memory _payees,
        uint256[] memory _paymentShares
    )
        ERC721("CryptorunnerNFT", "2112CR")
        PaymentSplitter(_payees, _paymentShares)
    {
        baseURI = _baseURI;
        proxyRegistryAddress = _proxyRegistryAddress;
        rootPassAddress = _rootPassAddress;
    }

    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function setPrice(uint256 _priceInWei) public onlyOwner {
        priceInWei = _priceInWei;
    }

    function setProvenance(string memory _provenance) public onlyOwner {
        provenance = _provenance;
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "Token does not exist.");
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), ".json"));
    }

    function setProxyRegistryAddress(address _proxyRegistryAddress) external onlyOwner {
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    function toggleSaleStatus() external onlyOwner {
        saleStatus = !saleStatus;
    }

    function mint(uint256 count) public payable {
        require(saleStatus, "Sale is not open");
        require(count * priceInWei == msg.value, "Invalid funds provided.");
        require(count < MAX_PER_TX, "Exceeds max per transaction.");
        uint256 totalSupply = _owners.length;
        require(totalSupply + count < MAX_SUPPLY, "Excedes max supply.");
        // block proxy contract minting
        require(msg.sender == tx.origin, 'msg.sender does not match tx.origin');
         
        for(uint i; i < count; i++) { 
            _mint(_msgSender(), totalSupply + i);
        }
    }

    function promoMint(uint _qty, address _to) public onlyOwner {
        require(MAX_GIVEAWAY - _qty >= 0, "Exceeds max giveaway.");
        uint256 totalSupply = _owners.length;
        require(totalSupply + _qty < MAX_SUPPLY, "Excedes max supply.");
        for (uint i = 0; i < _qty; i++) {
            _mint(_to, totalSupply + i);
        }
        MAX_GIVEAWAY -= _qty;
    }

    function redeemRootPass(address[] calldata _addr) public {
        for (uint i = 0; i < _addr.length; i++) {
            uint256[] memory ids = new uint256[](1);
            uint256[] memory amounts = new uint256[](1);
            ids[0] = 1;
            amounts[0] = RP(rootPassAddress).balanceOf(_addr[i], 1);
            if (amounts[0] > 0) {
                uint256 totalSupply = _owners.length;
                require(totalSupply + amounts[0] < MAX_SUPPLY, "Excedes max supply.");
                for (uint j = 0; j < amounts[0]; j++) {
                    _mint(_addr[i], totalSupply + j);
                }
                RP(rootPassAddress).burnFromRedeem(_addr[i], ids, amounts);
            }
        }
    }

    function burn(uint256 tokenId) public { 
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved to burn.");
        _burn(tokenId);
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            transferFrom(_from, _to, _tokenIds[i]);
        }
    }

    function batchSafeTransferFrom(address _from, address _to, uint256[] memory _tokenIds, bytes memory data_) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            safeTransferFrom(_from, _to, _tokenIds[i], data_);
        }
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds) external view returns (bool){
        for(uint256 i; i < _tokenIds.length; ++i ){
            if(_owners[_tokenIds[i]] != account)
                return false;
        }

        return true;
    }

    function isApprovedForAll(address _owner, address operator) public view override(ERC721) returns (bool) {
        OpenSeaProxyRegistry proxyRegistry = OpenSeaProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || projectProxy[operator]) return true;
        return super.isApprovedForAll(_owner, operator);
    }

    function _mint(address to, uint256 tokenId) internal virtual override {
        _owners.push(to);
        emit Transfer(address(0), to, tokenId);
    }
}

contract OwnableDelegateProxy { }
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}