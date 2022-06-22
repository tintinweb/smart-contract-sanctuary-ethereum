// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IAviumNFT.sol";
import "./utils/BuySignatureUtils.sol";

contract BuyHandler is ReentrancyGuard, BuySignatureUtils {
    address public immutable PROXY;
    uint256 public privatePrice;
    uint256 public buyLimit;
    address public recipientAddress;
    uint256 public privateStartTime;
    uint256 public privateEndTime;
    address public signer;
    mapping(address => uint256) public mintAmount;
    mapping(string => bool) public existedUuid;


    constructor(address proxy, uint256 _privatePrice, uint256 _privateStartTime, uint256 _privateEndTime) {
        require(_privateEndTime > _privateStartTime, "BuyHandler: the end time should be greater than the start time");
        PROXY = proxy;
        privatePrice = _privatePrice;
        privateStartTime = _privateStartTime;
        privateEndTime = _privateEndTime;
        buyLimit = 1;
        recipientAddress = msg.sender;
        signer = msg.sender;
    }

    event BuyEvent(
        string uuid,
        address to,
        uint256 quantity,
        uint256 currentIndex,
        uint256 price
    );

    event BuyRemainNFTsEvent(
        address to,
        uint256 quantity,
        uint256 currentIndex
    );

    /**
     * @dev Set the buy limit
     * @param _buyLimit the new buy limit
    */
    function setLimitBuy(uint256 _buyLimit) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        buyLimit = _buyLimit;
    }

    /**
     * @dev Set the signer address
     * @param _signer the new signer address
    */
    function setSignerAddress(address _signer) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        signer = _signer;
    }

    /**
     * @dev Set the recipient address 
     * @param _recipientAddress the new recipient address 
    */
    function setRecipientAddress(address _recipientAddress) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        recipientAddress = _recipientAddress;
    }

    /**
     * @dev Set the start time
     * @param _privateStartTime the new start time 
    */
    function setPrivateStartTime(uint256 _privateStartTime) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        require(
            _privateStartTime < privateEndTime,
            "BuyHandler: the end time should be greater than the start time"

        );
        privateStartTime = _privateStartTime;
    }

    /**
     @dev Set the private price
     @param _privatePrice the new private price
    */
    function setPrivatePrice(uint256 _privatePrice) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        privatePrice = _privatePrice;
    }

    /**
     * @dev Set the end time
     * @param _privateEndTime the new end time
    */
    function setPrivateEndTime(uint256 _privateEndTime) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        require(
            _privateEndTime > privateStartTime,
            "BuyHandler: the end time should be greater than the start time"
        );
        privateEndTime = _privateEndTime;
    }

    /**
     * @dev Buy NFT
     * @param _uuid the sale order id
     * @param _to the address will receive NFTs
     * @param _quantity the quantity of NFTs
     * @param _signature the signature to buy NFTs
     * @param _data data byte
    */
    function buy(
        string memory _uuid,
        address _to,
        uint256 _quantity,
        uint256 _userMaxMint,
        bytes memory _signature,
        bytes memory _data
    ) public payable nonReentrant {
        uint256 currentIndex = IAviumNFT(PROXY).getCurrentIndex();
        require(block.timestamp >= privateStartTime && block.timestamp <= privateEndTime, "BuyHandler: you can not buy nft at this time");
        require(verifyBuySignature(signer,_uuid, _to, _quantity, msg.sender, _userMaxMint, _signature), "BuyHandler: wrong signature");
        require(msg.sender == _to, "BuyHandler: the sender address should be the address that will receive NFTs");
        require(existedUuid[_uuid] != true, "BuyHandler: the uuid was existed");
        require(_quantity <= buyLimit, "BuyHandler: the quantity exceed the limit buy");
        require(currentIndex < IAviumNFT(PROXY).getTotalMint(), "BuyHandler: the total mint has been exeeded");
        require(mintAmount[msg.sender] < _userMaxMint, "BuyHandler: you can only buy up to the specific limition");
        mintAmount[msg.sender]+=_quantity;
        existedUuid[_uuid]=true;
        payable(recipientAddress).transfer(msg.value);
        IAviumNFT(PROXY).mint(_to, _quantity, _data);
        emit BuyEvent(_uuid, _to, _quantity, currentIndex, msg.value);
    }

    /**
     * @dev Buy the remaining NFTs
     * @param _to the address will receive NFTs
     * @param _data data byte
    */
    function buyRemainNFTs(
        address _to,
        bytes memory _data
    ) public payable nonReentrant {
        require(msg.sender == IAviumNFT(PROXY).owner(), "BuyHandler: only AviumNFT's owner");
        uint256 currentIndex = IAviumNFT(PROXY).getCurrentIndex();
        require(currentIndex < IAviumNFT(PROXY).getTotalMint(), "BuyHandler:the total mint has been exeeded");
        require(block.timestamp > privateEndTime, "BuyHandler: you can not buy the NFTs in this time");
        uint256 quantity = IAviumNFT(PROXY).getTotalMint() - currentIndex;
        IAviumNFT(PROXY).mint(_to, quantity, _data);
        emit BuyRemainNFTsEvent(_to, quantity, currentIndex);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IAviumNFT {
    
    function setRecipientAddress(address _recipientAddress) external;

    function getRecipientAddress() external returns(address);

    function getCurrentIndex() external view returns (uint256);

    function getTotalMint() external view returns (uint256);

    function mint(
        address to,
        uint256 quantity,
        bytes calldata _data
    ) external;

    function owner() external returns (address);

    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// Signature Verification

contract BuySignatureUtils {
    function getBuyMessageHash(
        string memory _uuid,
        address _to,
        uint256 _quantity,
        address _payer,
        uint256 _userMaxMint
    ) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_uuid, _to, _quantity, _payer, _userMaxMint));
    }


    // Verify signature function
    function verifyBuySignature(
        address _signer,
        string memory _uuid,
        address _to,
        uint256 _quantity,
        address _payer,
        uint256 _userMaxMint,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getBuyMessageHash(_uuid, _to, _quantity, _payer, _userMaxMint);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(ethSignedMessageHash, v, r, s) == _signer;
    }


    // Split signature to r, s, v
    function splitSignature(bytes memory _signature)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_signature.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );

    }
}