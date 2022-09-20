// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./draft-EIP712Upgradeable.sol";
import "./ERC721Upgradeable.sol";
import "./ERC721EnumerableUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./CountersUpgradeable.sol";
import "./Initializable.sol";
import "./IERC20Upgradeable.sol";

contract CelebrityUpgradeable is
    OwnableUpgradeable,
    EIP712Upgradeable,
    ERC721EnumerableUpgradeable
{
    struct BuyNFTStruct {
        string id;
        uint256 price;
        address tokenAddress;
        address refAddress;
        string nonce;
        string uri;
        bytes signature;
    }

    event BuyEvent(
        address indexed user,
        string id,
        uint256 tokenId,
        string nonce,
        address tokenAddress,
        uint256 price,
        uint64 timestamp
    );

    string private constant _SIGNING_DOMAIN = "NFT-Voucher";
    string private constant _SIGNATURE_VERSION = "1";
    string private baseURI;

    address public fundAddress;

    uint256 public commissionRate;

    mapping(string => bool) private _noncesMap;
    mapping(uint256 => string) private _tokenURIs;

    function initialize() public virtual initializer {
        __NFT_init();
    }

    function __NFT_init() internal  {
        __EIP712_init(_SIGNING_DOMAIN, _SIGNATURE_VERSION);
        __ERC721_init("Celebrity.sg", "Celebrity.sg");
        __Ownable_init();
        __NFT_init_unchained();
    }

    function __NFT_init_unchained() internal  {
        fundAddress = _msgSender();

        commissionRate = 10;
    }

    function returnID() public view returns (uint256) {
        return totalSupply();
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
            "ERC721URIStorage: URI query for nonexistent token"
        );

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _verifyNFTBuy(BuyNFTStruct calldata data)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashNFTBuy(data);
        return ECDSAUpgradeable.recover(digest, data.signature);
    }

    function _hashNFTBuy(BuyNFTStruct calldata data)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "BuyNFTStruct(string id,uint256 price,address tokenAddress,string nonce)"
                        ),
                        keccak256(bytes(data.id)),
                        data.price,
                        data.tokenAddress,
                        keccak256(bytes(data.nonce))
                    )
                )
            );
    }

    function buyNFT(BuyNFTStruct calldata data) public payable {
        address signer = _verifyNFTBuy(data);

        // Make sure that the signer is authorized to mint an item
        require(
            signer == owner() ,
            "Signature invalid or unauthorized"
        );

        // Check nonce
        require(!_noncesMap[data.nonce], "The nonce has been used");
        _noncesMap[data.nonce] = true;

        uint256 refAmount;
        uint256 price = data.price;

        if (data.refAddress != address(0)) {
            refAmount = (data.price * commissionRate) / 100;
            price = data.price - refAmount;
        }

        // Transfer payment
        if (data.tokenAddress == address(0)) {
            require(msg.value >= data.price, "Not enough money");
            (bool success, ) = fundAddress.call{value: price}("");
            require(success, "Transfer payment to admin failed");
            if (refAmount != 0) {
                (success, ) = data.refAddress.call{value: refAmount}("");
                require(success, "Transfer payment to ref failed");
            }
        } else {
            IERC20Upgradeable(data.tokenAddress).transferFrom(
                msg.sender,
                fundAddress,
                price
            );
            if (refAmount != 0) {
                IERC20Upgradeable(data.tokenAddress).transferFrom(
                    msg.sender,
                    data.refAddress,
                    refAmount
                );
            }
        }
        uint256 mintIndex = totalSupply() + 1000001;
        _safeMint(_msgSender(), mintIndex);
        _setTokenURI(mintIndex, data.uri);

        emit BuyEvent(
            _msgSender(),
            data.id,
            mintIndex,
            data.nonce,
            data.tokenAddress,
            data.price,
            uint64(block.timestamp)
        );
    }
}