//SPDX-License-Identifier: UNLICENSED

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

contract Building is ERC1155U, IERC2981, Ownable {
    using Base64 for *;
    using Strings for uint256;
    using SafeMath for uint256;
    uint256 _currentTokenId = 1;

    bool private _gaslessTrading = true;
    uint256 private _royaltyPartsPerMillion = 50_000;
    uint256 public _pricePerPix = 250000000 gwei;

    string public constant name = 'Fantom Board';
    string public constant symbol = 'FTMB';
    string public _dataProxyUri = "ipfs://";

    uint256 public _threshold = 6862;

    uint256 public _klonSum;

    event Chunk(uint256 indexed id, uint256 indexed position, uint256 ymax, uint256 ymaxLegal, uint256 nbpix, bytes image);
    mapping(uint256 => uint256) chunkBlocks;
    mapping (address => uint256) balances;
    mapping (address => uint256) pixelsMinted;


    address public constant creatorAddress = 0x68fCc097Fe3cFE23144af775334706244dddcA21;

    function draw2438054C(uint256 position, uint256 ymax, uint256 nbpix, address _address, bytes calldata image) external payable {
        require(ymax * 1000000  <= 192 * 1000000 + _klonSum * _threshold, "Out of board");
        require(msg.value >= nbpix * _pricePerPix, "Not enough eth");
        require(nbpix > 0, "Cannot send empty mark");
        uint256 index = _currentTokenId;
        _klonSum += nbpix;
        emit Chunk(_currentTokenId, position, ymax, 192 * 1000000 + _klonSum * _threshold, nbpix, image);
        emit TransferSingle(msg.sender, address(0), msg.sender, index, 1);
        _setOwner(index, msg.sender);

        uint256 balance = (7 * 10**16 * _pricePerPix * (pixelsMinted[_address] / _klonSum));
        balances[_address] = balance;

        unchecked {
            index++;
        }
        _currentTokenId = index;
    }


function claimFee(address _address) public {
    uint256 fee = balances[_address];
    payable(_address).transfer(fee);
    require(fee > 0, "No fee to claim");
    balances[_address] = 0;
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
            '"description": "Fantom Board","external_url": "https://fantom-board.netlify.app","animation_url": "',
            _dataProxyUri,
            _tokenId.toString(),
            '","image":"ipfs://QmVVoQMUZ29Qz2yPVERmP5GJ4Lor9dxPcHjdcPFATbmM53"',
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
        _withdraw(creatorAddress, address(this).balance);
    }

    function _withdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

}