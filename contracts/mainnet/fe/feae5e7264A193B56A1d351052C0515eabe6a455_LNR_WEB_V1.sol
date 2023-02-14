/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: DERP
// By Derp Herpenstein derp://derpnation.og, https://www.derpnation.xyz

pragma solidity ^0.8.4;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


interface ILNR_RESOLVER {
   function verifyIsNameOwner(bytes32 _name, address _addr) external view returns(bool);
}

contract LNR_WEB_V1 is ReentrancyGuard {

    event NewAsset(bytes32 indexed assetHash, string assetName, string assetDescription);
    event NewWebsite(bytes32 indexed domain, bytes data);
    event NewState(bytes32 indexed domain, address indexed user, uint256 version, bytes state);

    struct Website{
      bytes32 pageHash;
      bytes32 pageTxHash;
    }

    address public constant lnrResolverAddress = 0x6023E55814DC00F094386d4eb7e17Ce49ab1A190; // resolver
    mapping(bytes32 => Website) public lnrWebsites; // maps a domain to a web address

  function getWebsite(bytes32 _domain) public view returns(Website memory){
    return(lnrWebsites[_domain]);
  }

  function updateWebsite(bytes32 _domain, bytes32 _pageHash, bytes32 _pageTxHash, bytes calldata _data) public nonReentrant{
    require(ILNR_RESOLVER(lnrResolverAddress).verifyIsNameOwner(_domain, msg.sender) == true, "Not your domain");
    lnrWebsites[_domain].pageHash = _pageHash;
    lnrWebsites[_domain].pageTxHash = _pageTxHash;
    emit NewWebsite(_domain, _data);
  }

  function uploadAssets(bytes32[] calldata _assetHash, string[] calldata _assetName, string[] calldata _assetHeaders, 
                        string[] calldata _assetDescription, bytes[] calldata _assetData) external {
    uint i = 0;
    for(; i< _assetName.length;){
      emit NewAsset(_assetHash[i], _assetName[i], _assetDescription[i]);
      unchecked {++i;}
    }
  }

  function uploadAsset( bytes32 _assetHash, bytes32 _nextChunk, string calldata _assetName, string calldata _assetHeaders, 
                        string calldata _assetDescription, bytes calldata _assetData) external {
    emit NewAsset(_assetHash, _assetName, _assetDescription);
  }

  function updateState(bytes32 _domain, uint256 _version, bytes calldata _state) external {
    emit NewState(_domain, msg.sender, _version, _state);
  }

}