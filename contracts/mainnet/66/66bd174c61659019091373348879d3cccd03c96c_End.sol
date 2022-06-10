// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/interfaces/IERC2981.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ERC721A.sol";
import "./Ownable.sol";
import "./IERC2981.sol";
import "./IERC20.sol";

/**********************************************
 ******** In the end, there is no end. ********
 **********************************************/

contract End is ERC721A, IERC2981, Ownable {
    bool public theend;
    string public limbo;
    address public void;
    uint256 public constant nightmares = 667;
    mapping(address => bool) public souls;

    constructor() ERC721A("The End", "END") {}

    function joinToEnd() external {
        uint256 demons = _totalMinted();

        require(msg.sender == tx.origin, "must be someone");
        require(theend, "there is no end");
        require(!souls[msg.sender], "already in the end");
        require(demons + 1 <= nightmares, "the end is once");

        _mint(msg.sender, 1);
        souls[msg.sender] = true;
    }

    function generateNightmare(address soul, uint256 nightmare) external onlyOwner {
        uint256 demons = _totalMinted();
        require(demons + nightmare <= nightmares, "too much");

        _mint(soul, nightmare);
    }

    function end(bool _theend) external onlyOwner {
        theend = _theend;
    }

    function bind(string calldata _limbo) external onlyOwner {
        limbo = _limbo;
    }

    function fall(address _void) external onlyOwner {
        void = _void;
    }

    function alchemy() external onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success);
    }

    function alchemize(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(msg.sender, balance);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return limbo;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        require(_exists(tokenId), "in the limbo");
        return (void, (salePrice * 7) / 100);
    }
}