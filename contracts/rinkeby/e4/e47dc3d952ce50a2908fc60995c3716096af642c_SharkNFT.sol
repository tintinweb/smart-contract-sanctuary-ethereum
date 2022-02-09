pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";
import "./Ownable.sol";

contract SharkNFT is ERC721PresetMinterPauserAutoId, Ownable {

    string private _baseTokenURI;
    string private _notRevealedURI;

    uint256 _price = 0.02 ether; // 0.02 ETH
    uint256 _grPrice = 3500000000; // 3500 GR

    bool public revealed = false;

    IERC20 private grom;

   constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        string memory notRevealedURI,
        IERC20 gromContract
    ) ERC721PresetMinterPauserAutoId(name, symbol) {
        _baseTokenURI = baseTokenURI;
        _notRevealedURI = notRevealedURI;
        grom = gromContract;

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

        revealed = true;
    }

    function setGrPrice(uint256 amount) public virtual {
        require(hasRole(ADMIN_ROLE, _msgSender()), "SharkNFT: must have admin role to change data");

        _grPrice = amount;
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

     function ethMint() public payable {
        require(msg.value >= _price, "SharkNFT: amount sent is not correct");
        
        mint(msg.sender);
    }

    function grMint(uint256 _amount) public {
        require(_amount >= _grPrice, "SharkNFT: amount sent is not correct");

        uint256 allowance = grom.allowance(msg.sender, address(this));

        require(allowance >= _amount, "SharkNFT: Check the token allowance");

        (bool sent) = grom.transferFrom(msg.sender, address(this), _amount);
        require(sent, "Failed to send GROM");

        mint(msg.sender);
    }

    /**
    * @notice Allow contract owner to withdraw ETH to its own account.
    */
    function withdrawEth() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
    * @notice Allow contract owner to withdraw GR to its own account.
    */
    function withdrawGr() external onlyOwner {
        uint256 balance = grom.balanceOf(address(this));
        require(balance > 0, "SharkNFT: amount sent is not correct");

        grom.transfer(owner(), balance);
    }
}