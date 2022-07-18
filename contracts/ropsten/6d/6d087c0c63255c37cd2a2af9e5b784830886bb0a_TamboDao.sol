// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import './ERC721A.sol';
import './Ownable.sol';
import './ReentrancyGuard.sol';

contract TamboDao is ERC721A, Ownable, ReentrancyGuard {  
    using Strings for uint256;
    string public _tamboslink;
    bool public liberate = false;
    uint256 public tambos = 501;
    uint256 public liberatetambo = 1; 
    mapping(address => uint256) public howmanytambos;
   
	constructor() ERC721A("TamboDao", "PPC") {}

    address public a1;
    address public a2;
    address public a3;

    function _baseURI() internal view virtual override returns (string memory) {
        return _tamboslink;
    }

 	function makeTambos() external nonReentrant {
  	    uint256 totaltambos = totalSupply();
        require(liberate);
        require(totaltambos + liberatetambo <= tambos);
        require(msg.sender == tx.origin);
    	require(howmanytambos[msg.sender] < liberatetambo);
        _safeMint(msg.sender, liberatetambo);
        howmanytambos[msg.sender] += liberatetambo;
    }

 	function getTambos(address own, uint256 _tambos) public onlyOwner {
  	    uint256 totaltambos = totalSupply();
	    require(totaltambos + _tambos <= tambos);
        _safeMint(own, _tambos);
    }

    function liberatetheTambos(bool _bye) external onlyOwner {
        liberate = _bye;
    }

    function setFree(uint256 _liberate) external onlyOwner {
        liberatetambo = _liberate;
    }

    function TambosHomeparts(string memory parts) external onlyOwner {
        _tamboslink = parts;
    }

    function setAddresses(address[] memory _a) public onlyOwner {
        a1 = _a[0];
        a2 = _a[1];
        a3 = _a[2];
    }

    function withdrawTeam(uint256 amount) public payable onlyOwner {
        uint256 percent = amount / 100;
        require(payable(a1).send(percent * 40));
        require(payable(a2).send(percent * 30));
        require(payable(a3).send(percent * 30));
    }
}