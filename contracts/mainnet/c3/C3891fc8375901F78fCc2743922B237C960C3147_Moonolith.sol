pragma solidity ^0.8.9;

import './Ownable.sol';
import './ERC1155U.sol';
import './Base64.sol';
import './Strings.sol';
import './IERC20.sol';
import './SafeMath.sol';


interface ProxyRegistry {
    function proxies(address) external view returns (address);
}

interface IERC2981 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract Moonolith is ERC1155U, IERC2981, Ownable {
    using Base64 for *;
    using Strings for uint256;
    using SafeMath for uint256;
    uint256 _currentTokenId = 1;

    bool private _gaslessTrading = true;
    uint256 private _royaltyPartsPerMillion = 50_000;
    uint256 public _pricePerPix = 25000 gwei;

    string public constant name = 'Moonolith';
    string public constant symbol = 'MOON';
    string public _dataProxyUri = "ipfs://";

    uint256 public _threshold = 6862;

    uint256 public _klonSum;

    event Chunk(uint256 indexed id, uint256 indexed position, uint256 ymax, uint256 ymaxLegal, uint256 nbpix, bytes image);
    mapping(uint256 => uint256) chunkBlocks;

    address public constant creator1Address = 0x2D59325C5E9BB0e40d125Eefa1Da4c3793C604c7;
    address public constant creator2Address = 0x474e00810333F3362c17480C3Ba9eBC75507af2D;
    address public constant creator3Address = 0x0a7792C2fD7bF4bC25f4d3735E8aD9f59570aCBe;
    address public constant creator4Address = 0x1C592Db0c01413b8c857534B373A5f96c058968F;


    function draw2438054C(uint256 position, uint256 ymax, uint256 nbpix, bytes calldata image) external payable {
        require(ymax * 1000000  <= 192 * 1000000 + _klonSum * _threshold, "Out of monolith");
        require(msg.value >= nbpix * _pricePerPix, "Not enough eth");
        require(nbpix > 0, "Cannot send empty mark");
        uint256 index = _currentTokenId;
        _klonSum += nbpix;
        emit Chunk(_currentTokenId, position, ymax, 192 * 1000000 + _klonSum * _threshold, nbpix, image);
        emit TransferSingle(msg.sender, address(0), msg.sender, index, 1);
        _setOwner(index, msg.sender);
        unchecked {
            index++;
        }
        _currentTokenId = index;
    }

    function totalSupply() public view returns (uint256) {
        unchecked {
            // Starts at index 1
            return _currentTokenId - 1;
        }
    }

    function getMonolithInfo() public view returns (uint256 supply, uint256 threshold, uint256 klonTotal, uint256 price) {
        return (totalSupply(), _threshold, _klonSum, _pricePerPix);
    }

    function uri(uint256 _tokenId) public view virtual override returns (string memory) {
		require(_tokenId <= _currentTokenId, "URI query for nonexistent token");

		bytes memory baseURI = (abi.encodePacked(
			'{', 
            '"description": "Moonolith","external_url": "https://moonolith.io","animation_url": "',
            _dataProxyUri,
            _tokenId.toString(),
            '","image":"ipfs://QmYJ5ZSMjTAuhQeJMZgcuVG2u2eFyJejgL8bDRjwpKsgSb/"',
            '}'
		));
	
		return string(abi.encodePacked(
			"data:application/json;base64,",
			baseURI.encode()
		));
			
	}

    function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
        receiver = owner();
        royaltyAmount = (salePrice * _royaltyPartsPerMillion) / 1_000_000;
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        if (_gaslessTrading) {
                if (ProxyRegistry(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(owner) == operator) {
                    return true;
                }
        }
        return super.isApprovedForAll(owner, operator);
    }

    // Admin
    
    function setAllowGaslessListing(bool allow) public onlyOwner {
        _gaslessTrading = allow;
    }

    function setDataProxyUri(string calldata newProxy ) public onlyOwner {
        _dataProxyUri = newProxy;
    }

    function setThreshold(uint256 threshold) public onlyOwner {
        _threshold = threshold;
    }

    function setPrice(uint256 price) public onlyOwner {
        _pricePerPix = price;
    }

    function setRoyaltyPPM(uint256 newValue) public onlyOwner {
        require(newValue < 1_000_000, 'Must be < 1e6');
        _royaltyPartsPerMillion = newValue;
    }


    function withdraw() external {
        uint256 b = address(this).balance;
        _withdraw(creator1Address, b.mul(325).div(1000));
        _withdraw(creator2Address, b.mul(325).div(1000));
        _withdraw(creator4Address, b.mul(100).div(1000));
        _withdraw(creator3Address, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function withdrawERC20(IERC20 erc20Token) public onlyOwner {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }
}