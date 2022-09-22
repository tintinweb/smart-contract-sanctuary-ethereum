// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Marketplace Management for NFT marketplace
/// @author Monkhub Innovations
/// @notice This smart contract manages marketplace owner's funds
/// @dev

contract MarketManagement is ReentrancyGuard {
    // address[4] signers;
    // uint256 nonce;
    // bytes32 public messageHash;
    // address public fundsWithdrawer;
    // address[] whiteList;
    uint256 private earnings;
    address private owner;
    uint256 public earningCommission;
    bool public isMarketplace;
    mapping(address => bool) private shopCreators;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access this function");
        _;
    }

    constructor(
        address _owner,
        uint256 _earningCommission, // 900 for 9%
        bool _isMarketplace
    ) 
    {
        require(
            _earningCommission >= 0 && _earningCommission <= 1000,
            "Commission percentage must be between 0 and 10%"
        ); // 0 <= newCommissionn <= 10%
        owner = _owner;
        earningCommission = _earningCommission;
        isMarketplace = _isMarketplace;
        emit MarketInitiated(address(this),_isMarketplace);
    }

    event MarketInitiated(
        address indexed _fundManager,
        bool indexed _isMarketplace
    );

    event EarningsWithdrawn(
        address indexed _fundManager,
        uint256 indexed _amtWithdrawn
    );

    event AddedShopCreator(
        address indexed MarketManager,
        address indexed creator
    );
    event RemovedShopCreator( 
        address indexed MarketManager,
        address indexed creator
    );
    event MarketCommissionChanged(
        address indexed MarketManager,
        uint256 new_commission  // 1111 is 11.11%
    );

    

    receive() external payable {
    }

    fallback() external payable {
    }

    function balance() external view returns (uint256) {
        return earnings;
    }

    function withdrawEarnings(uint256 _amount, address payable _to)
        public
        onlyOwner
    {
        require(_amount <= earnings, "Not enough balance!!!");
        earnings -= _amount;
        // bool processed = false;
        // for (uint256 i = 0; i < whiteList.length; i++) {
        //     if (whiteList[i] == _to) {
        //         processed = true;
        //         break;
        //     }
        // }
        // require(processed == true, "Address not present in whitelist!!!");
        emit EarningsWithdrawn(address(this), _amount);
        _to.transfer(_amount);
    }

    function changeOwnerAddress(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "Owner cannot be null address!");
        owner = _newOwner;
    }

    function changeEarningCommission(uint256 newCommission) public onlyOwner {
        require(
            newCommission >= 0 && newCommission <= 1000,
            "Commission percentage must be between 0 and 10%"
        ); // 0 <= newCommissionn <= 10%
        earningCommission = newCommission;
        emit MarketCommissionChanged(address(this), newCommission);
    }

    function isShopCreator(address _addr) external view returns (bool) {
        require(!isMarketplace, "Marketplaces have no shop creators");
        require(_addr != address(0), "Null address cannot be creator");
        if (_addr == owner) return true;
        else return (shopCreators[_addr]);
    }

    function addShopCreator(address _addr) public onlyOwner {
        require(!isMarketplace, "Marketplaces have no shop creators");
        require(_addr != address(0), "Null address cannot be creator");
        require(!shopCreators[_addr], "Already a shop creator");
        shopCreators[_addr] = true;
        emit AddedShopCreator(address(this), _addr);
    }

    function removeShopCreator(address _addr) public onlyOwner {
        require(!isMarketplace, "Marketplaces have no shop creators");
        require(_addr != address(0), "Null address cannot be creator");
        require(shopCreators[_addr], "Already not a shop creator");
        shopCreators[_addr] = false;
        emit RemovedShopCreator(address(this), _addr);
    }

    // function viewWhiteList() public view returns (address[] memory) {
    //     require(
    //         msg.sender == fundsWithdrawer ||
    //             msg.sender == signers[0] ||
    //             msg.sender == signers[1] ||
    //             msg.sender == signers[2] ||
    //             msg.sender == signers[3],
    //         "Invalid caller!!!"
    //     );
    //     return whiteList;
    // }
    // // changes address of fundsWithdrawer
    // function changeAddress(bytes[4] memory sigs, address _newAddress) public {
    //     require(
    //         msg.sender == signers[0] ||
    //             msg.sender == signers[1] ||
    //             msg.sender == signers[2] ||
    //             msg.sender == signers[3],
    //         "Invalid caller!!!"
    //     );
    //     uint256 count = 0;
    //     for (uint256 i = 0; i < 4; i++) {
    //         if (verify(signers[i], sigs[i])) count++;
    //     }
    //     if (count >= 3) {
    //         fundsWithdrawer = _newAddress;
    //     }
    //     nonce = nonce + 1;
    //     messageHash = keccak256(
    //         abi.encodePacked(
    //             signers[0],
    //             signers[1],
    //             signers[2],
    //             signers[3],
    //             nonce
    //         )
    //     );
    // }

    // function addToWhiteList(bytes[4] memory sigs, address _address) public {
    //     require(
    //         msg.sender == signers[0] ||
    //             msg.sender == signers[1] ||
    //             msg.sender == signers[2] ||
    //             msg.sender == signers[3],
    //         "Invalid caller!!!"
    //     );
    //     uint256 count = 0;
    //     for (uint256 i = 0; i < 4; i++) {
    //         if (verify(signers[i], sigs[i])) count++;
    //     }
    //     if (count >= 3) {
    //         whiteList.push(_address);
    //     }
    //     nonce = nonce + 1;
    //     messageHash = keccak256(
    //         abi.encodePacked(
    //             signers[0],
    //             signers[1],
    //             signers[2],
    //             signers[3],
    //             nonce
    //         )
    //     );
    // }

    // function removeFromWhiteList(bytes[4] memory sigs, address _address)
    //     public
    // {
    //     require(
    //         msg.sender == signers[0] ||
    //             msg.sender == signers[1] ||
    //             msg.sender == signers[2] ||
    //             msg.sender == signers[3],
    //         "Invalid caller!!!"
    //     );
    //     uint256 count = 0;
    //     for (uint256 i = 0; i < 4; i++) {
    //         if (verify(signers[i], sigs[i])) count++;
    //     }
    //     if (count >= 3) {
    //         int256 pos = -1;
    //         for (uint256 j = 0; j < whiteList.length; j++) {
    //             if (whiteList[j] == _address) {
    //                 pos = int256(j);
    //             }
    //         }
    //         if (pos != -1) {
    //             for (uint256 k = uint256(pos); k < whiteList.length - 1; k++) {
    //                 whiteList[k] = whiteList[k + 1];
    //             }
    //             whiteList.pop();
    //         }
    //     }
    //     nonce = nonce + 1;
    //     messageHash = keccak256(
    //         abi.encodePacked(
    //             signers[0],
    //             signers[1],
    //             signers[2],
    //             signers[3],
    //             nonce
    //         )
    //     );
    // }

    // function getEthSignedMessageHash(bytes32 _messageHash)
    //     internal
    //     pure
    //     returns (bytes32)
    // {
    //     /*
    //     Signature is produced by signing a keccak256 hash with the following format:
    //     "\x19Ethereum Signed Message\n" + len(msg) + msg
    //     */
    //     return
    //         keccak256(
    //             abi.encodePacked(
    //                 "\x19Ethereum Signed Message:\n32",
    //                 _messageHash
    //             )
    //         );
    // }

    // function verify(address _signer, bytes memory signature)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
    //     return recoverSigner(ethSignedMessageHash, signature) == _signer;
    // }

    // function recoverSigner(
    //     bytes32 _ethSignedMessageHash,
    //     bytes memory _signature
    // ) internal pure returns (address) {
    //     (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

    //     return ecrecover(_ethSignedMessageHash, v, r, s);
    // }

    // function splitSignature(bytes memory sig)
    //     internal
    //     pure
    //     returns (
    //         bytes32 r,
    //         bytes32 s,
    //         uint8 v
    //     )
    // {
    //     require(sig.length == 65, "invalid signature length");

    //     assembly {
    //         /*
    //         First 32 bytes stores the length of the signature

    //         add(sig, 32) = pointer of sig + 32
    //         effectively, skips first 32 bytes of signature

    //         mload(p) loads next 32 bytes starting at the memory address p into memory
    //         */

    //         // first 32 bytes, after the length prefix
    //         r := mload(add(sig, 32))
    //         // second 32 bytes
    //         s := mload(add(sig, 64))
    //         // final byte (first byte of the next 32 bytes)
    //         v := byte(0, mload(add(sig, 96)))
    //     }

    //     // implicitly return (r, s, v)
    // }
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