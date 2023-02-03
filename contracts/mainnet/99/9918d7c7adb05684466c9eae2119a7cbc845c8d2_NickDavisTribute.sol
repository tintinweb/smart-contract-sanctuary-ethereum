// SPDX-License-Identifier: GPL-3.0
// ----------    Friends of Nick Davis   ----------
// ----------   Tribute NFT Collection   ----------

pragma solidity 0.8.10;

import "./ERC1155Burnable.sol";
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";

import {DefaultOperatorFilterer} from "./DefaultOperatorFilterer.sol";
contract OwnableDelegateProxy {}

/**
 * Used to delegate ownership of a contract to another address, to save on unneeded transactions to approve contract use for users
 */
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NickDavisTribute is ERC1155Burnable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {
	using Strings for uint256;

    uint256 public currentTokenID = 1;
	uint256 public totalMinted = 0;
    uint256 public totalWithdrawn = 0;
    
	address public minter;
	bool public isMintingEnabled = true;

    uint256 public price = 0.01 ether;
    uint256 public maxPerTx = 10;

	string private _baseTokenURI = "https://houseoffirst.com:1335/tribute/opensea/";
	string private _contractURI = "https://houseoffirst.com:1335/tribute/opensea/";

    address public proxyRegistryAddress = 0xa5409ec958C83C3f309868babACA7c86DCB077c1; // OpenSea Mainnet Proxy Registry address

	event CustomAction(uint256 nftID, uint256 value, uint256 actionID, string payload);
	string public name;

	constructor() ERC1155(_baseTokenURI) {
		name = "Friends Of Nick Davis";
		minter = msg.sender;
        setStartEndTimesForToken(1, 1675429200, 0);
        setStartEndTimesForToken(2, 1675429200, 0);
        setStartEndTimesForToken(3, 1675429200, 0);
        setStartEndTimesForToken(4, 1675429200, 0);
	}

    address[] internal _burners;
    uint256[] internal _burntTokenIds;
    uint256[] internal _burntTokenAmounts;
    address[] internal _owners;
    mapping(address => bool) public addressIsAnOwner;
	mapping(uint256 => bool) public tokenIdBurnEnabled;
	mapping(uint256 => uint256) public tokenIdTotalSupply;
	mapping(uint256 => uint256) public tokenIdStartTimes;
	mapping(uint256 => uint256) public tokenIdEndTimes;


	function totalSupply() public view virtual returns (uint256) {
		uint256 total = 0;
        for(uint256 tokenId = 0; tokenId <= currentTokenID; tokenId++) {
            total += tokenIdTotalSupply[tokenId];
        }
		return total;
    }

	function totalSupplyForTokenId(uint256 tokenId) public view virtual returns (uint256) {
		return tokenIdTotalSupply[tokenId];
    }

    // returns current owners
    function getOwners() external view returns (address[] memory) {
        return _owners;
    }

    function getBurners() external view returns (address[] memory) {
        return _burners;
    }

    function getBurntTokenIds() external view returns (uint256[] memory) {
        return _burntTokenIds;
    }

    function getBurntTokenAmounts() external view returns (uint256[] memory) {
        return _burntTokenAmounts;
    }

    function setCurrentTokenId(uint256 newCurrentTokenID) public onlyOwner {
		currentTokenID = newCurrentTokenID;
	}

	function setTokenIdBurnEnabled(uint256 tokenId, bool burnEnabled) public onlyOwner {
		tokenIdBurnEnabled[tokenId] = burnEnabled;
	}

	function canBurnToken(uint256 tokenId) public view returns (bool) {
		return tokenIdBurnEnabled[tokenId];
	}

    function addressIsOwner(address addr) public view returns (bool) {
        return addressIsAnOwner[addr];
    }

    function getNFTPrice() public view returns (uint256) {
        return price;
    }

    function getTokenIdStartTime(uint256 tokenId) public view returns (uint256) {
        return tokenIdStartTimes[tokenId];
    }

    function getTokenIdEndTime(uint256 tokenId) public view returns (uint256) {
        return tokenIdEndTimes[tokenId];
    }

    function getCurrentStartTime() public view returns (uint256) {
        return getTokenIdStartTime(currentTokenID);
    }

    function getCurrentEndTime() public view returns (uint256) {
        return getTokenIdEndTime(currentTokenID);
    }

	function tokenBalancesByAddress(address addr) public view returns(uint256[] memory) {
		uint256[] memory tokenBals = new uint256[](currentTokenID + 1);
		for(uint256 tokenId = 0; tokenId <= currentTokenID; tokenId++) {
			tokenBals[tokenId] = balanceOf(addr, tokenId);
		}
		return tokenBals;
	}

	function tokenOwnershipsByAddress(address addr) public view returns(bool[] memory) {
		bool[] memory tokenOwnerships = new bool[](currentTokenID + 1);
		for(uint256 tokenId = 0; tokenId <= currentTokenID; tokenId++) {
			tokenOwnerships[tokenId] = balanceOf(addr, tokenId) > 0;
		}
		return tokenOwnerships;
	}

	// mint 1 type of NFT with quantity x to the receiver
	function mint(
		address receiver,
		uint256 quantity,
		bytes memory data // "0x"
	) payable external {
		require(isMintingEnabled, "minting disabled");
        require(block.timestamp >= getCurrentStartTime(), "minting not open yet");
        require(block.timestamp < getCurrentEndTime(), "minting closed");
        require(quantity > 0 && quantity <= maxPerTx, "Invalid quantity");
        require(msg.value >= price * quantity, "Not Enough ETH");
		_mint(receiver, currentTokenID, quantity, data);
	}

    function isMintingOpen() public view returns(bool) {
        if(!isMintingEnabled) {
            return false;
        }
        if(block.timestamp < getCurrentStartTime()) {
            return false;
        }
        if(block.timestamp > getCurrentEndTime()) {
            return false;
        }
        return true;
    }

	// airdrops an NFT
	function airdrop(
		address[] memory receivers,
		uint256[] memory quantities,
		uint256[] memory tokenIds,
		bytes[] memory datas // "0x"
	) external {
		require(receivers.length == quantities.length, "arrays should be equal");
		require(receivers.length == tokenIds.length, "arrays should be equal 2");
		require(msg.sender == minter, "only minter account can call this");
		require(isMintingEnabled == true, "minting disabled");
		for (uint256 i = 0; i < receivers.length; i++) {
			_mint(receivers[i], tokenIds[i], quantities[i], datas[i]);
		}
	}

	function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
		require(id <= currentTokenID, "token id does not exist");
		super._mint(to, id, amount, data);
		tokenIdTotalSupply[id] += amount;
        if(!addressIsAnOwner[to]) {
            _owners.push(to);
            addressIsAnOwner[to] = true;
        }
	}

    // transfers NFTs
	function transferMany(
		address[] memory receivers,
		uint256[] memory quantities,
		uint256[] memory tokenIds,
		bytes[] memory datas // "0x0"
	) external {
		require(receivers.length == quantities.length, "arrays should be equal");
		require(receivers.length == tokenIds.length, "arrays should be equal 2");
		require(msg.sender == minter, "only minter account can call this");
		for (uint256 i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];
            uint256 tokenId = tokenIds[i];
            uint256 quantity = quantities[i];
            _safeTransferFrom(msg.sender, receiver, tokenId, quantity, datas[i]);
		}
	}

	function customAction(
		uint256 tokenId,
		uint256 id,
		string memory what
	) external payable {
		require(balanceOf(msg.sender, tokenId) > 0, "NFT ownership required");
        require(tokenId <= currentTokenID, "token id does not exist");
		emit CustomAction(tokenId, msg.value, id, what);
	}

    function getTotalBalance(address addr) public view returns(uint256) {
        uint256 totalBal = 0;
        for(uint256 tokenId = 0; tokenId <= currentTokenID; tokenId++) {
            totalBal += balanceOf(addr, tokenId);
        }
        return totalBal;
    }

	function uri(uint256 tokenId) public view override returns (string memory) {
		return string(abi.encodePacked(_baseTokenURI, uint2str(tokenId)));
	}

	function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
    	return string(abi.encodePacked(_baseTokenURI, uint2str(tokenId)));
    }

	//sets the minter address
	function setMinter(address _newMinter) public onlyOwner {
		minter = _newMinter;
	}

	function toggleMinting(bool _enabled) public onlyOwner {
		isMintingEnabled = _enabled;
	}

	function contractURI() public view returns (string memory) {
		return _contractURI;
	}

	function withdrawETH() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		_baseTokenURI = newBaseURI;
	}

	function setContractURI(string memory newuri) public onlyOwner {
		_contractURI = newuri;
	}

    function setMaxPerTx(uint256 newMax) public onlyOwner {
		maxPerTx = newMax;
	}

    function setStartEndTimesForToken(uint256 tokenId, uint256 startTime, uint256 endTime) public onlyOwner {
        tokenIdStartTimes[tokenId] = startTime;
        if(endTime == 0) {
            endTime = startTime + 24 * 60 * 60;
        }
        tokenIdEndTimes[tokenId] = endTime;
    }

	function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
		if (_i == 0) {
			return "0";
		}
		uint256 j = _i;
		uint256 len;
		while (j != 0) {
			len++;
			j /= 10;
		}
		bytes memory bstr = new bytes(len);
		uint256 k = len;
		while (_i != 0) {
			k = k - 1;
			uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
			bytes1 b1 = bytes1(temp);
			bstr[k] = b1;
			_i /= 10;
		}
		return string(bstr);
	}

    function removeAddressFromOwners(address addr) internal {
        for (uint256 i; i < _owners.length; i++) {
            if (_owners[i] == addr) {
                _owners[i] = _owners[_owners.length - 1];
                _owners.pop();
                addressIsAnOwner[addr] = false;
                break;
            }
        }
    }

    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        // add recipient to list of owners
        if(to != address(0) && !addressIsAnOwner[to]) {
            _owners.push(to);
            addressIsAnOwner[to] = true;
        }
        // sent to the 0 address (burnt)
        if(to == address(0)) {
            for(uint256 i = 0; i < amounts.length; i++) {
                uint256 id = ids[i];
                uint256 amt = amounts[i];
                _burners.push(from);
                _burntTokenIds.push(id);
                _burntTokenAmounts.push(amt);
            }
        }
        // remove sender if they are no longer a holder
        if(from != address(0) && getTotalBalance(from) == 0) {
            removeAddressFromOwners(from);
        }
        super._afterTokenTransfer(operator, from, to, ids, amounts, data);
    }

	function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
		if(msg.sender != minter) {
			require(canBurnToken(id), "token burning for this id is not enabled");
		}
		super.burn(account, id, value);
		tokenIdTotalSupply[id] -= value;
	}

	function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
		for(uint256 i = 0; i < ids.length; i++) {
			if(msg.sender != minter) {
				require(canBurnToken(ids[i]), "token burning for this id is not enabled");
			}
			tokenIdTotalSupply[ids[i]] -= values[i];
		}
		super.burnBatch(account, ids, values);
	}

    function getTotalWithdrawn() public view returns (uint256) {
        return totalWithdrawn;
    }

    function getTotalBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalRaised() public view returns (uint256) {
        return getTotalWithdrawn() + getTotalBalance();
    }

    /**
     * withdraw ETH from the contract (callable by Owner only)
     */
    function withdraw() public payable onlyOwner {
        uint256 val = address(this).balance;
        (bool success, ) = payable(msg.sender).call{
            value: val
        }("");
        require(success);
        totalWithdrawn += val;
        delete val;
    }
    /**
     * whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) override public view returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }
}