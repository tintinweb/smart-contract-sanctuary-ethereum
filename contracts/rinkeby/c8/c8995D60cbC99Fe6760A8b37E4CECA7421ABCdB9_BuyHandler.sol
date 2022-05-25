// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IAviumNFT.sol";
import "./utils/BuySignatureUtils.sol";

contract BuyHandler is ReentrancyGuard, BuySignatureUtils {
    address public immutable PROXY;
    uint256 public price;
    uint256 public limitBuy;
    address public recipientAddress;
    uint256 public startTime;
    address public signer;

    constructor(address proxy, uint256 _price) {
        PROXY = proxy;
        price = _price;
        limitBuy = 1;
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

    /**
     * @dev Set limit buy
     * @param _limitBuy limit that owner want to set is the limit buy
    */
    function setLimitBuy(uint256 _limitBuy) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        limitBuy = _limitBuy;
    }

    /**
     * @dev Set Signer address
     * @param _signer address that owner want to set is the signer address
    */
    function setSignerAddress(address _signer) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        signer = _signer;
    }

    /**
     * @dev Set receive address 
     * @param _recipientAddress address that owner want to set to receive address 
    */
    function setRecipientAddress(address _recipientAddress) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        recipientAddress = _recipientAddress;
    }

    /**
     * @dev Set start time for mint NFT
     * @param _startTime the time that the owner wants to set is the start time 
    */
    function setStartTime(uint256 _startTime) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        startTime = _startTime;
    }

    /**
     @dev Set price
     @param _price the price that the owner want to set is the nft price
    */
    function setPrice(uint256 _price) public {
        require(
            msg.sender == IAviumNFT(PROXY).owner(),
            "BuyHandler: only AviumNFT's owner"
        );
        price = _price;
    }

    /**
     * @dev Buy NFT
     * @param _uuid sale order id
     * @param _to address will receive NFT
     * @param _quantity nft quantity
     * @param _signature signature for buy NFT
     * @param _data data byte
    */
    function buy(
        string memory _uuid,
        address _to,
        uint256 _quantity,
        bytes memory _signature,
        bytes memory _data
    ) public payable nonReentrant {
        uint256 currentIndex = IAviumNFT(PROXY).getCurrentIndex();
        require(
            msg.value == _quantity * price,
            "BuyHandler: invalid amount value"
        );
        require(verifyBuySignature(signer,_uuid, _to, _quantity, msg.sender, IAviumNFT(PROXY).getCurrentIndex(), _signature), "BuyHandler: wrong signature");
        require(
            block.timestamp > startTime, "BuyHandler: it haven't been time to start mint"
        );
        require(
            _quantity <= limitBuy, "BuyHandler: the quantity exceed the limit buy"
        );
        require(
            currentIndex < IAviumNFT(PROXY).getTotalMint(), "BuyHandler: total mint has been exeeded"
        );
        payable(recipientAddress).transfer(msg.value);
        IAviumNFT(PROXY).mint(_to, _quantity, _data);
        emit BuyEvent(_uuid, _to, _quantity, currentIndex, price);
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
        uint256 _currentIndex
    ) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_uuid, _to, _quantity, _payer, _currentIndex));
    }


    // Verify signature function
    function verifyBuySignature(
        address _signer,
        string memory _uuid,
        address _to,
        uint256 _quantity,
        address _payer,
        uint256 _currentIndex,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getBuyMessageHash(_uuid, _to, _quantity, _payer, _currentIndex);
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