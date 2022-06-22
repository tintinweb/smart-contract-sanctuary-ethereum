/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
// Deployed at: 0x16c0e3D33B332E9BFab3A2de322cBA7Ca02c0638

pragma solidity ^0.8.0;


//PROXY PROGRAM TO EXTEND MINTING CAPABILITIES OF THE NFT-PANDEMIC CONTRACT



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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is 0x address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract Functional {
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
    
    bool private _reentryKey = false;
    modifier reentryLock {
        require(!_reentryKey, "attempt reenter locked function");
        _reentryKey = true;
        _;
        _reentryKey = false;
    }
}

contract PANDEMIC {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance){}
    function ownerOf(uint256 tokenId) external view returns (address owner){}
    function safeTransferFrom(address from,address to,uint256 tokenId) external{}
    function transferFrom(address from, address to, uint256 tokenId) external{}
    function approve(address to, uint256 tokenId) external{}
    function getApproved(uint256 tokenId) external view returns (address operator){}
    function setApprovalForAll(address operator, bool _approved) external{}
    function isApprovedForAll(address owner, address operator) external view returns (bool){}
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external{}


    //required calls:

    function totalSupply() external view returns (uint256) {}

    //proxy access functions:
    function proxyMint(address to, uint256 tokenId) external {
    //transfer from 0x00 and totalSupply()+1
    }
    
    function proxyBurn(uint256 tokenId) external {
    //transfer to 0x00 and totalSupply()-1
    }
    
    function proxyTransfer(address from, address to, uint256 tokenId) external {
    //	_transfer(from, to, tokenId);
    }
}

contract PandemicExtension is Ownable, Functional {

    uint256 maxSupply = 6666;
    uint256 collectionStart = 10000;
    uint256 lottoCap = 100;
    
    bool lottoActive;
    bool spawnActive;
    bool mutateActive;
    
    mapping (address => bool) received;
    mapping (uint256 => bool) claimed;

    address[] lotteryHolders;
    uint256[] lotteryTokens;

    PANDEMIC proxy = PANDEMIC(0x4Ad8A7406Caac3457981A1B3C88B8aAB00D6e13d);

	function sneeze(address to, uint256 tokenId) external reentryLock {
		uint256 curSupply = proxy.totalSupply();
		require(proxy.ownerOf(tokenId) == _msgSender(), "Invalid tokenId");
		require(curSupply < maxSupply - 2, "Supply Drained");
		require(received[to] == false, "Already sneezed on");
		
		received[to] = true;
		
		proxy.proxyTransfer(_msgSender(), to, tokenId);
		proxy.proxyMint(to, curSupply);
		proxy.proxyMint(to, curSupply + 1);
	}
	
	///////////////////////////////////// LOTTO Section ////////////////////
	
	function enterLottery(uint256 tokenId) external reentryLock {
		require(lottoActive, "Entry Unavailable");
		require(proxy.ownerOf(tokenId) == _msgSender(), "Invalid tokenId");
        require(lotteryHolders.length < lottoCap, "Entries Filled");
		
		lotteryHolders.push(_msgSender());
		lotteryTokens.push(tokenId);
		
		proxy.proxyBurn(tokenId);
	}
	
	function countLottoTickets() external view returns (uint256) {
		return lotteryHolders.length;
	}
	
	function awardLottoWinner(uint256 ticketId) external onlyOwner {
		address to = lotteryHolders[ticketId];
		uint256 tokenId = lotteryTokens[ticketId];
		
		proxy.proxyMint(to, tokenId);
		_clearLottery();
	}
	
	function scanTokenId(uint ticketId) external view returns (uint256) {
		//failsafe to ensure the winning token can be tracked.
		return lotteryTokens[ticketId];
	}

	function scanTokenWinner(uint ticketId) external view returns (address) {
		//failsafe to ensure the winner can be tracked.
		return lotteryHolders[ticketId];
	}
		
	function _clearLottery() internal {
		for (uint256 i=0; i < lotteryHolders.length; i++){
			lotteryHolders.pop();
			lotteryTokens.pop();
		}
	}

    function setLottoCapLimit(uint256 newLimit) external onlyOwner {
        lottoCap = newLimit;
    }
	
	function activateLotto() external onlyOwner {
		lottoActive = true;
	}
	
	function deactivateLotto() external onlyOwner {
		lottoActive = false;
	}

	/////////////////////////////////// NEW Collections ///////////////////
	
	function spawn(uint256 tokenId) external reentryLock {
        uint256 newToken = tokenId + collectionStart;
        require(tokenId < 10000, "Only for OG Virus");
        require(spawnActive, "Not Ready");
        require(proxy.ownerOf(tokenId) == _msgSender(), "Invalid tokenId");
		require(claimed[newToken] == false, "AlreadyIssued");

        claimed[newToken] == true;
        proxy.proxyMint(_msgSender(), newToken);
	}
	
	function mutate(uint256 tokenId) external reentryLock {
        uint256 newToken = tokenId + collectionStart;
        require(tokenId < 10000, "Only for OG Virus");
        require(mutateActive, "Not Ready");
        require(proxy.ownerOf(tokenId) == _msgSender(), "Invalid tokenId");
		require(claimed[newToken] == false, "AlreadyIssued");

        claimed[newToken] == true;
        proxy.proxyBurn( tokenId );
        proxy.proxyMint(_msgSender(), newToken);
	}
	
	function setCollectionStart(uint256 newCollectionTId) external onlyOwner {
        collectionStart = newCollectionTId;
	}
	
	function activateSpawn() external onlyOwner {
		spawnActive = true;
	}
	
	function activateMutate() external onlyOwner {
        mutateActive = true;
	}
	
	function deactivateSpawn() external onlyOwner {
        spawnActive = false;
	}
	
	function deactivateMutate() external onlyOwner {
        mutateActive = true;
	}
	
}