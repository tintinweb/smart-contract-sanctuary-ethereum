// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC721A.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./Payment.sol";

contract Linforme is ERC721A, Ownable, Payment {
    using Strings for uint256;

    string public baseURI1 = "ipfs://QmX9sBCJWzivbZnKb32wg1s66mURsY3G4xdzHhi1u4Z5ij/";
    string public baseURI2 = "ipfs://QmQxCg1g97Z73KWCGBWqF4GA2JhmcLXSpxQRzLBBGrQA4R/";
    string public baseURI3 = "ipfs://QmWiGLGnVPQboAkPB2NUfyXgS8BFCgNRPtcRwcitTv29kA/";
    string public baseURI4 = "ipfs://Qma7izPmayB8QmssfLCuthh73e9k5rW3mxY58yXni3L7rj/";
    string public baseURI5 = "ipfs://QmaHjEE9teHZ6x9HNUoS2v2Z7qAXhcHDbb2wyejmRuyGWr/";

    //settings
	uint256 public END_PRICE; // can change, on start of sale
	uint256 public START_PRICE; // can change, on start of sale
	bool public status = false;
	uint256 public saleDuration;
    uint256 public saleStartTime;

      //shares
	address[] private addressList = [
	0xc8Dbf5715f9B00C592EfC049a9705cBee4901E34, 
    0x41Fb9227c703086B2d908E177A692EdCD3d7DE2C,
	0xEcc03efB7C0A7BD09A5cC7e954Ac42E8f949A0B5
	];

	uint[] private shareList = [
	90,
	5,
	5
	];

    event saleStart( uint256 indexed _Duration, uint256 indexed _saleStartTime);
	event salePaused(uint256 indexed _currentPrice,uint256 indexed _elapsedTime);

    constructor()
    Payment(addressList, shareList) 
    ERC721A("Linforme", "LINFORME") {
    }

	function startAuction(uint256 Duration, uint256 startPrice, uint256 endPrice) external onlyOwner {
    /*
    Duration	uint256	86400 sec = 24 hours
    startPrice	uint256	8000000000000000000 wei = 8.0ETH
    endPrice	uint256	3000000000000000000 wei = 3.0ETH
    */
        require(!status, "Auction is live");
        require(startPrice >= endPrice);
        saleDuration = Duration;
        START_PRICE = startPrice;
        END_PRICE = endPrice;
        saleStartTime = block.timestamp;
        status = true;
        emit saleStart(Duration, saleStartTime);
    }

	function pauseAuction() external onlyOwner {
        require(status, "Auction is not livie");
        uint256 currentPrice = getPrice();
	    uint256 elapsedTime = getElapsedTime();
        saleStartTime = 0;
        status = false;
        emit salePaused(currentPrice, elapsedTime);
    }

    uint256 public token0Index;
    bool public token0minted;
  
	function mintToken0() external payable{
        require(status,"Auction is not live");
        require(!token0minted,"Token already minted");
        uint256 cost = getPrice();
        uint256 s = totalSupply();
        require(cost <= msg.value, "Ether value sent is not correct");
        token0Index = s + 1;
        _safeMint(msg.sender, 1);
        token0minted = true;
    	if (msg.value > cost) {
            Address.sendValue(payable(msg.sender), msg.value - cost);
        }
    }

    uint256 public token1Index;
    bool public token1minted;
  
	function mintToken1() external payable{
        require(status,"Auction is not live");
        require(!token1minted,"Token already minted");
        uint256 cost = getPrice();
        uint256 s = totalSupply();
        require(cost <= msg.value, "Ether value sent is not correct");
        token1Index = s + 1;
        _safeMint(msg.sender, 1);
        token1minted = true;
    	if (msg.value > cost) {
            Address.sendValue(payable(msg.sender), msg.value - cost);
        }
    }

    uint256 public token2Index;
    bool public token2minted;
  
	function mintToken2() external payable{
        require(status,"Auction is not live");
        require(!token2minted,"Token already minted");
        uint256 cost = getPrice();
        uint256 s = totalSupply();
        require(cost <= msg.value, "Ether value sent is not correct");
        token2Index = s + 1;	
        _safeMint(msg.sender, 1);
        token2minted = true;
    	if (msg.value > cost) {
            Address.sendValue(payable(msg.sender), msg.value - cost);
        }
    }

	uint256 public token3Index;
    bool public token3minted;
  
	function mintToken3() external payable{
        require(status,"Auction is not live");
        require(!token3minted,"Token already minted");
        uint256 cost = getPrice();
        uint256 s = totalSupply();
        require(cost <= msg.value, "Ether value sent is not correct");
        token3Index = s + 1;	
        _safeMint(msg.sender, 1);
        token3minted = true;
    	if (msg.value > cost) {
            Address.sendValue(payable(msg.sender), msg.value - cost);
        }
    }

    uint256 public token4Index;
    bool public token4minted;
  
	function mintToken4() external payable{
        require(status,"Auction is not live");
        require(!token4minted,"Token already minted");
        uint256 cost = getPrice();
        uint256 s = totalSupply();
        require(cost <= msg.value, "Ether value sent is not correct");
        token4Index = s + 1;	
        _safeMint(msg.sender, 1);
        token4minted = true;
    	if (msg.value > cost) {
            Address.sendValue(payable(msg.sender), msg.value - cost);
        }
    }

	function getPrice() public view returns (uint256) {
		if (!status) {
			return 0;
        }
        uint256 elapsed = getElapsedTime();
        if (elapsed >= saleDuration) {
            return END_PRICE;
        } else {
            int256 tPrice = int256(START_PRICE) +
                ((int256(END_PRICE) -
                    int256(START_PRICE)) /
                    int256(saleDuration)) *
                int256(elapsed);
            uint256 currentPrice = uint256(tPrice);
            return currentPrice > END_PRICE ? currentPrice : END_PRICE;
        }
    }

	function getElapsedTime() internal view returns (uint256) {
        return
            saleStartTime > 0 ? block.timestamp - saleStartTime : 0;
    }

	function getRemainingTime() external view returns (uint256) {
        if (saleStartTime == 0) {
            return 604800; //returns one week, this is the equivalent with publicSale has not started yet
        }
        if (getElapsedTime() >= saleDuration) {
            return 0;
        }
        return (saleStartTime + saleDuration) - block.timestamp;
    }

	//read metadata
	function _baseURI1() internal view virtual returns (string memory) {
    	return baseURI1;
	}
	function _baseURI2() internal view virtual returns (string memory) {
	    return baseURI2;
	}
	function _baseURI3() internal view virtual returns (string memory) {
	    return baseURI3;
	}
	function _baseURI4() internal view virtual returns (string memory) {
	    return baseURI4;
	}
	function _baseURI5() internal view virtual returns (string memory) {
	    return baseURI5;
	}

	function tokenURI(uint256 id) public view virtual override returns (string memory) {
      require(_exists(id), "Token has not been minted yet");
         if(id == 0 && token0Index == 1){ string memory currentBaseURI1 = _baseURI1(); return bytes(currentBaseURI1).length > 0	? string(abi.encodePacked(currentBaseURI1)) : "";}
    else if(id == 0 && token1Index == 1){ string memory currentBaseURI2 = _baseURI2(); return bytes(currentBaseURI2).length > 0	? string(abi.encodePacked(currentBaseURI2)) : "";}
    else if(id == 0 && token2Index == 1){ string memory currentBaseURI3 = _baseURI3(); return bytes(currentBaseURI3).length > 0	? string(abi.encodePacked(currentBaseURI3)) : "";}
    else if(id == 0 && token3Index == 1){ string memory currentBaseURI4 = _baseURI4(); return bytes(currentBaseURI4).length > 0	? string(abi.encodePacked(currentBaseURI4)) : "";}
    else if(id == 0 && token4Index == 1){ string memory currentBaseURI5 = _baseURI5(); return bytes(currentBaseURI5).length > 0	? string(abi.encodePacked(currentBaseURI5)) : "";}
    else if(id == 1 && token0Index == 2){ string memory currentBaseURI1 = _baseURI1(); return bytes(currentBaseURI1).length > 0	? string(abi.encodePacked(currentBaseURI1)) : "";}
    else if(id == 1 && token1Index == 2){ string memory currentBaseURI2 = _baseURI2(); return bytes(currentBaseURI2).length > 0	? string(abi.encodePacked(currentBaseURI2)) : "";}
    else if(id == 1 && token2Index == 2){ string memory currentBaseURI3 = _baseURI3(); return bytes(currentBaseURI3).length > 0	? string(abi.encodePacked(currentBaseURI3)) : "";}
    else if(id == 1 && token3Index == 2){ string memory currentBaseURI4 = _baseURI4(); return bytes(currentBaseURI4).length > 0	? string(abi.encodePacked(currentBaseURI4)) : "";}
    else if(id == 1 && token4Index == 2){ string memory currentBaseURI5 = _baseURI5(); return bytes(currentBaseURI5).length > 0	? string(abi.encodePacked(currentBaseURI5)) : "";}
    else if(id == 2 && token0Index == 3){ string memory currentBaseURI1 = _baseURI1(); return bytes(currentBaseURI1).length > 0	? string(abi.encodePacked(currentBaseURI1)) : "";}
    else if(id == 2 && token1Index == 3){ string memory currentBaseURI2 = _baseURI2(); return bytes(currentBaseURI2).length > 0	? string(abi.encodePacked(currentBaseURI2)) : "";}
    else if(id == 2 && token2Index == 3){ string memory currentBaseURI3 = _baseURI3(); return bytes(currentBaseURI3).length > 0	? string(abi.encodePacked(currentBaseURI3)) : "";}
    else if(id == 2 && token3Index == 3){ string memory currentBaseURI4 = _baseURI4(); return bytes(currentBaseURI4).length > 0	? string(abi.encodePacked(currentBaseURI4)) : "";}
    else if(id == 2 && token4Index == 3){ string memory currentBaseURI5 = _baseURI5(); return bytes(currentBaseURI5).length > 0	? string(abi.encodePacked(currentBaseURI5)) : "";}
    else if(id == 3 && token0Index == 4){ string memory currentBaseURI1 = _baseURI1(); return bytes(currentBaseURI1).length > 0	? string(abi.encodePacked(currentBaseURI1)) : "";}
    else if(id == 3 && token1Index == 4){ string memory currentBaseURI2 = _baseURI2(); return bytes(currentBaseURI2).length > 0	? string(abi.encodePacked(currentBaseURI2)) : "";}
    else if(id == 3 && token2Index == 4){ string memory currentBaseURI3 = _baseURI3(); return bytes(currentBaseURI3).length > 0	? string(abi.encodePacked(currentBaseURI3)) : "";}
    else if(id == 3 && token3Index == 4){ string memory currentBaseURI4 = _baseURI4(); return bytes(currentBaseURI4).length > 0	? string(abi.encodePacked(currentBaseURI4)) : "";}
    else if(id == 3 && token4Index == 4){ string memory currentBaseURI5 = _baseURI5(); return bytes(currentBaseURI5).length > 0	? string(abi.encodePacked(currentBaseURI5)) : "";}
    else if(id == 4 && token0Index == 5){ string memory currentBaseURI1 = _baseURI1(); return bytes(currentBaseURI1).length > 0	? string(abi.encodePacked(currentBaseURI1)) : "";}
    else if(id == 4 && token1Index == 5){ string memory currentBaseURI2 = _baseURI2(); return bytes(currentBaseURI2).length > 0	? string(abi.encodePacked(currentBaseURI2)) : "";}
    else if(id == 4 && token2Index == 5){ string memory currentBaseURI3 = _baseURI3(); return bytes(currentBaseURI3).length > 0	? string(abi.encodePacked(currentBaseURI3)) : "";}
    else if(id == 4 && token3Index == 5){ string memory currentBaseURI4 = _baseURI4(); return bytes(currentBaseURI4).length > 0	? string(abi.encodePacked(currentBaseURI4)) : "";}
    else if(id == 4 && token4Index == 5){ string memory currentBaseURI5 = _baseURI5(); return bytes(currentBaseURI5).length > 0	? string(abi.encodePacked(currentBaseURI5)) : "";}
    else{
        return "Token has not been minted yet";
    }
	}

    //write metadata
	function setURI1(string memory _newBaseURI) public onlyOwner {
		baseURI1 = _newBaseURI;
	}
	function setURI2(string memory _newBaseURI) public onlyOwner {
		baseURI2 = _newBaseURI;
	}
	function setURI3(string memory _newBaseURI) public onlyOwner {
		baseURI3 = _newBaseURI;
	} 
	function setURI4(string memory _newBaseURI) public onlyOwner {
		baseURI4 = _newBaseURI;
	}
	function setURI5(string memory _newBaseURI) public onlyOwner {
		baseURI5 = _newBaseURI;
	}

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(owner()), balance);
    }
}