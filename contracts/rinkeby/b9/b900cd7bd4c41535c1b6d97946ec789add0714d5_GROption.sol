pragma solidity ^0.8.0;

import "./ERC721PresetMinterPauserAutoId.sol";
import "./Ownable.sol";

contract GROption is ERC721PresetMinterPauserAutoId, Ownable {

    string private _baseTokenURI;

    bool public revealed = false;

    IERC20 private grom;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        IERC20 gromContract
    ) ERC721PresetMinterPauserAutoId(name, symbol) {
        _baseTokenURI = baseTokenURI;
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
        require(hasRole(ADMIN_ROLE, _msgSender()), "GROption: must have admin role to change data");
        revealed = !revealed;
    }

    function setBaseTokenURI(string memory _URI) public virtual {
        require(hasRole(ADMIN_ROLE, _msgSender()), "GROption: must have admin role to change data");

        _baseTokenURI = _URI;
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
            "GROption: URI query for nonexistent token"
        );
        return
        bytes(_baseTokenURI).length > 0
        ? string(
            abi.encodePacked(
                _baseTokenURI,
                Strings.toString(tokenId)
            )
        )
        : "";
    }

    function multipleMint(uint256 _numOfTokens) external onlyOwner {
        for (uint256 i = 0; i < _numOfTokens; i++) {
            mint(msg.sender);
        }
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
        require(balance > 0, "GROption: amount sent is not correct");

        grom.transfer(owner(), balance);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(hasRole(ADMIN_ROLE, _msgSender()), "GROption: must have admin role to change data");
        super._transfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual override {
        require(hasRole(ADMIN_ROLE, _msgSender()), "GROption: must have admin role to change data");

        super._approve(to, tokenId);
    }
}