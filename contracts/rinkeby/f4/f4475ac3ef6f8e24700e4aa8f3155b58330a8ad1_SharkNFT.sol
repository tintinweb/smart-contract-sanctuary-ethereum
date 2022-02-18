pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";
import "./Ownable.sol";

contract SharkNFT is ERC721PresetMinterPauserAutoId, Ownable {

    string private _baseTokenURI;
    string private _notRevealedURI;

    uint256 _price = 0.002 ether; // 0.02 ETH

    bool public revealed = false;
    bool public isPresale = false;

    uint256 private constant TOTAL_NFT = 8500;

    mapping (address => bool) public whitelist;

   constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory notRevealedURI
    ) ERC721PresetMinterPauserAutoId(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _notRevealedURI = notRevealedURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function reveal() public virtual {
        require(hasRole(ADMIN_ROLE, _msgSender()), "SharkNFT: must have admin role to change data");

        revealed = !revealed;
    }

    function setPresaleStatus() public virtual {
        require(hasRole(ADMIN_ROLE, _msgSender()), "SharkNFT: must have admin role to change data");

        isPresale = !isPresale;
    }

    function setBaseTokenURI(string memory _URI) public virtual {
        require(hasRole(ADMIN_ROLE, _msgSender()), "SharkNFT: must have admin role to change data");

        _baseTokenURI = _URI;
    }

    function setNotRevealedTokenURI(string memory _URI) public virtual {
        require(hasRole(ADMIN_ROLE, _msgSender()), "SharkNFT: must have admin role to change data");

        _notRevealedURI = _URI;
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
            "SharkNFT: URI query for nonexistent token"
        );

        string memory currentBaseURI = revealed ? _baseTokenURI : _notRevealedURI;
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        Strings.toString(tokenId)
                    )
                )
                : "";
    }

    function multipleEthMint(uint256 _numOfTokens) public payable {
        require(totalSupply() + _numOfTokens <= TOTAL_NFT, "SharkNFT: can't mint more than 8500");
        require(msg.value >= _numOfTokens * _price, "SharkNFT: amount sent is not correct");

        (bool success, string memory reason) = canMint(msg.sender);
        require(success, reason);

        for (uint256 ind = 0; ind < _numOfTokens; ind++) {
            safeMint(msg.sender, _numOfTokens);
        }
    }

    function multipleMint(uint256 _numOfTokens) external onlyOwner {
        require(totalSupply() + _numOfTokens <= TOTAL_NFT, "SharkNFT: can't mint more than 8500");

        for (uint256 ind = 0; ind < _numOfTokens; ind++) {
            safeMint(msg.sender, _numOfTokens);
        }
    }

    function addMultipleToWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 10000, "SharkNFT: provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
    }

    function removeMultipleFromWhitelist(address[] calldata _addresses) external onlyOwner {
        require(_addresses.length <= 10000, "SharkNFT: provide less addresses in one function call");
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
    }

    function canMint(address _address) public view returns (bool, string memory) {
        if (!whitelist[_address] && isPresale) {
            return (false, "SharkNFT: only for whitelist");
        }

        return (true, "");
    }

    /**
    * @notice Allow contract owner to withdraw ETH to its own account.
    */
    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}