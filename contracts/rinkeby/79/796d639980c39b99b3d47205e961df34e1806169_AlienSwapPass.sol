// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./ERC721.sol";
import "./ECDSA.sol";
import "./ReentrancyGuard.sol";


contract AlienSwapPass is Context, Ownable, ERC721, ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint256 public constant CAP = 3000;
    uint256 public constant EARLYBIRD_AMOUNTS = 1000;
    uint256 public constant EARLYBIRD_PRICE = 5 * 1e16;   // 0.05 ETH
    uint256 public constant NORMAL_PRICE = 1 * 1e17;   // 0.1 ETH
    uint256 public maxPerAddress = 1;

    bool public saleIsActive;
    Counters.Counter private _currentId;
    uint256 private _totalSold = 0;
    mapping(address => uint256) private _boughtNum;
    address private _validator;

    event BuyAlienSwapPass(address indexed to, uint256 indexed mintIndex);


    constructor() ERC721("AlienSwap Pass", "AlienPass") public {
        saleIsActive = false;
        _validator = msg.sender;
    }

    function setSaleIsActive(bool newState) public onlyOwner {
        saleIsActive = newState;
    }

    function setValidator(address newValidator) public onlyOwner {
        _validator = newValidator;
    }

    // start from tokenId = 1
    function buyAlienSwapPass(bytes calldata signature) public payable nonReentrant{
        require(_msgSender() == tx.origin, "contract can not buy");
        require(saleIsActive, "sale does not start yet");
        require(_boughtNum[_msgSender()].add(1) <= maxPerAddress, "can not exceed purchase limits");
        require(_totalSold.add(1) <= CAP, "can not exceed max cap");
        if (_totalSold < (EARLYBIRD_AMOUNTS + 1)) {
            require(msg.value >= EARLYBIRD_PRICE, "ETH sent is not enough");
        } else {
            require(msg.value >= NORMAL_PRICE, "ETH sent is not enough");
        }

        // check signature
        address signer = tryRecover(whitelistHash(_msgSender()), signature);
        require(signer == _validator, "check signature error");

        _boughtNum[_msgSender()] = _boughtNum[_msgSender()].add(1);
        _totalSold = _totalSold.add(1);
        _currentId.increment();
        uint256 mintIndex = _currentId.current();
        _safeMint(_msgSender(), mintIndex);

        emit BuyAlienSwapPass(_msgSender(), mintIndex);
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setTokenURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setTokenURI(tokenId, tokenURI);
    }

    function withdrawETH(address payable to) external onlyOwner {
        to.transfer(balanceOf(address(this)));
    }

    function whitelistHash(address account) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function tryRecover(bytes32 hashCode, bytes memory signature) public pure returns (address) {
        return ECDSA.recover(hashCode, signature);
    }

}