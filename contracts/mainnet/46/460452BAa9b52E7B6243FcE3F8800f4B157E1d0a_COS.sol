//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import './Ownable.sol';
import './IERC20.sol';
import './ERC1155U.sol';
import "./SafeMath.sol";
import "./Strings.sol";



interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract COS is ERC1155U, IERC2981, Ownable {
    using SafeMath for uint256;
    using Strings for uint256;

    uint256 _currentTokenId = 1;

    uint256 public constant MAX_TOKENS = 4999;
    uint256 constant TOKENS_GIFT = 80;
    uint256 public PRICE = 0.25 ether;
    
    uint256 public giftedAmount;
    uint256 public presalePurchaseLimit = 3;
    bool public presaleLive;
    bool public saleLive;
    bool public locked;
    bool public revealed = false; 


    string private _tokenBaseURI = 'ipfs://QmQaZBeLfvrpfwuGCE7Q4iHrjzzngrminW8rgEdJUSoJgr/';

    bool private _gaslessTrading = true;
    uint256 private _royaltyPartsPerMillion = 50_000;

    string public constant name = 'Clash of Shiba';
    string public constant symbol = 'COS';

    mapping(address => bool) public presalerList;
    uint256 public currentWave;
    mapping(uint256 => mapping(address => uint256)) public presalerListPurchases;

    modifier notLocked {
        require(!locked, "Contract metadata methods are locked");
        _;
    }

    function send(address to) external onlyOwner {
        require(_currentTokenId <= MAX_TOKENS, 'Sold out');
        require(giftedAmount <= TOKENS_GIFT, 'Sold out');
        giftedAmount++;
        _mint(to, _currentTokenId, '');

        unchecked {
            // Can't overflow
            _currentTokenId++;
        }
    }

    function send_Several(address[] calldata to) external onlyOwner {
        unchecked {
            // Can't overflow
            require(_currentTokenId - 1 + to.length <= MAX_TOKENS, 'Sold out');
            require(giftedAmount + to.length <= TOKENS_GIFT, "Finito");
        }

        for (uint256 i = 0; i < to.length;) {
            giftedAmount++;
            _mint(to[i], _currentTokenId, '');
            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                _currentTokenId++;
                i++;
            }
        }
    }

    function mint_Several_nmW(uint256 count) external payable {
        require(count < 6, 'Max 5');
        require(saleLive);
        unchecked {
            // Can't overflow
            require(_currentTokenId - 1 + count <= MAX_TOKENS, 'Sold out');
            require(count * PRICE == msg.value, 'Wrong price');
        }

        uint256[] memory ids = new uint256[](count);

        for (uint256 i = 0; i < count; ) {
            ids[i] = _currentTokenId + i;
            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        _batchMint(msg.sender, ids, '');

        unchecked {
            // Can't overflow
            _currentTokenId += count;
        }
    }

    function addToPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            require(!presalerList[entry], "DUPLICATE_ENTRY");

            presalerList[entry] = true;
        }   
    }


    function removeFromPresaleList(address[] calldata entries) external onlyOwner {
        for(uint256 i = 0; i < entries.length; i++) {
            address entry = entries[i];
            require(entry != address(0), "NULL_ADDRESS");
            
            presalerList[entry] = false;
        }
    }

    function mint_Presale(uint256 count) external payable {
        require(count <= presalePurchaseLimit, 'Max <');
        require(presaleLive, "PRESALE_CLOSED");
        require(presalerListPurchases[currentWave][msg.sender] + count <= presalePurchaseLimit, "EXCEED_ALLOC");

        unchecked {
            // Can't overflow
            require(_currentTokenId + count < MAX_TOKENS, 'Sold out');
            require(count * PRICE == msg.value, 'Wrong price');
        }

        uint256[] memory ids = new uint256[](count);

        for (uint256 i = 0; i < count; ) {
            ids[i] = _currentTokenId + i;
            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        _batchMint(msg.sender, ids, '');

        unchecked {
            // Can't overflow
            _currentTokenId += count;
        }
    }

    function totalSupply() public view returns (uint256) {
        unchecked {
            // Starts with 1
            return _currentTokenId - 1;
        }
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        require(_currentTokenId >= tokenId, "Cannot query non-existent token");
        if (revealed) {
            return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
        }else {
            return  _tokenBaseURI;
        }
        
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (salePrice * _royaltyPartsPerMillion) / 1_000_000;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        // Allow easier listing for sale on OpenSea. Based on
        // https://github.com/ProjectOpenSea/opensea-creatures/blob/f7257a043e82fae8251eec2bdde37a44fee474c4/migrations/2_deploy_contracts.js#L29
        if (_gaslessTrading) {
            if (block.chainid == 4) {
                if (ProxyRegistry(0xF57B2c51dED3A29e6891aba85459d600256Cf317).proxies(owner) == operator) {
                    return true;
                }
            } else if (block.chainid == 1) {
                if (ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(owner) == operator) {
                    return true;
                }
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    // Admin

    function setBaseURI(string calldata URI) external onlyOwner notLocked {
        _tokenBaseURI = URI;
        revealed = true;
    }

    function setAllowGaslessListing(bool allow) public onlyOwner {
        _gaslessTrading = allow;
    }

    function setRoyaltyPPM(uint256 newValue) public onlyOwner {
        require(newValue < 1_000_000, 'Must be < 1e6');
        _royaltyPartsPerMillion = newValue;
    }

    function setPrice(uint256 _price) public onlyOwner {
        PRICE = _price;
    }

    function toggleSaleStatus() public onlyOwner {
        saleLive = !saleLive;
    }

    function isPresaler(address addr) external view returns (bool) {
        return presalerList[addr];
    }
    
    function presalePurchasedCount(address addr) external view returns (uint256) {
        return presalerListPurchases[currentWave][addr];
    }

    function nextWave(uint256 newLimit) public onlyOwner {
        currentWave = currentWave + 1;
        presalePurchaseLimit = newLimit;
    }

    function lockMetadata() public onlyOwner {
        locked = true;
    }
    
    function togglePresaleStatus() public onlyOwner {
        presaleLive = !presaleLive;
    }
    

    function withdraw() external onlyOwner {
        _widthdraw(msg.sender, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }
    function widthrawERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }
}