// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";

interface IPaymentToken {
    function burn(address account, uint256 amount) external;
}

contract NftPool is Ownable {
    string public constant CONTRACT_NAME = "NftPool";
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant BUY_NFT_TYPEHASH =
        keccak256(
            "BuyNft(address tokenAddress,uint256 tokenId,address buyer,uint256 amount)"
        );

    IPaymentToken public paymentToken;

    address public admin = 0x019dCf8781F46Cb0880E3Ee68E1Aad165827FA04;

    event WithdrawNft(address tokenAddress, uint256 tokenId, address user);
    event BuyNft(
        address tokenAddress,
        uint256 tokenId,
        address user,
        uint256 amount
    );

    constructor() {}

    function setPaymentToken(IPaymentToken _paymentToken) external onlyOwner {
        paymentToken = _paymentToken;
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        admin = newAdmin;
    }

    function withdrawNft(address tokenAddress, uint256 tokenId)
        external
        onlyOwner
    {
        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);
        emit WithdrawNft(tokenAddress, tokenId, msg.sender);
    }

    function buyNft(
        address tokenAddress,
        uint256 tokenId,
        address buyer,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(CONTRACT_NAME)),
                getChainId(),
                address(this)
            )
        );
        bytes32 structHash = keccak256(
            abi.encode(BUY_NFT_TYPEHASH, tokenAddress, tokenId, buyer, amount)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory == admin, "Invalid signatory");

        IPaymentToken(paymentToken).burn(msg.sender, amount);

        IERC721(tokenAddress).transferFrom(address(this), msg.sender, tokenId);

        emit BuyNft(tokenAddress, tokenId, msg.sender, amount);
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}